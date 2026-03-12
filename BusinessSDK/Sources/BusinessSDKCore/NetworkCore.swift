import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var method: HTTPMethod { get }
    var body: Data? { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var requiresAuthorization: Bool { get }
}

public enum NetworkError: Error, Sendable {
    case url(URLError)
    case invalidResponse
    case unauthorized
    case httpStatus(code: Int, data: Data)
    case noData
    case decoding(Error)
}

public protocol SecurityKitProtocol: Sendable {
    func getAccessToken() async -> String?
    func refreshAccessToken() async throws
    func clearTokens() async
}

public actor NoOpSecurityKit: SecurityKitProtocol {
    public init() {}

    public func getAccessToken() async -> String? { nil }
    public func refreshAccessToken() async throws {}
    public func clearTokens() async {}
}

public actor RefreshGate {
    public init() {}

    public func refreshIfNeeded(_ operation: @Sendable () async throws -> Void) async throws {
        try await operation()
    }
}

public protocol NetworkEngineProtocol: Sendable {
    func request<T: APIRequest>(_ requestConfig: T) async throws -> T.Response
}

public final class NetworkEngine: NetworkEngineProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let security: SecurityKitProtocol
    private let decoder: JSONDecoder
    private let refreshGate: RefreshGate

    public init(
        baseURL: URL,
        security: SecurityKitProtocol = NoOpSecurityKit(),
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        refreshGate: RefreshGate = RefreshGate()
    ) {
        self.baseURL = baseURL
        self.security = security
        self.session = session
        self.decoder = decoder
        self.refreshGate = refreshGate
    }

    public func request<T: APIRequest>(_ requestConfig: T) async throws -> T.Response {
        let url = try makeURL(for: requestConfig)
        var request = URLRequest(url: url)
        request.httpMethod = requestConfig.method.rawValue
        request.httpBody = requestConfig.body

        requestConfig.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if requestConfig.requiresAuthorization, let token = await security.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await perform(request, as: T.self, didRetryAfterRefresh: false)
    }

    private func makeURL<T: APIRequest>(for requestConfig: T) throws -> URL {
        let endpoint = requestConfig.path.hasPrefix("/") ? String(requestConfig.path.dropFirst()) : requestConfig.path
        let url = baseURL.appendingPathComponent(endpoint)

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidResponse
        }

        if !requestConfig.queryItems.isEmpty {
            components.queryItems = requestConfig.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidResponse
        }

        return finalURL
    }

    private func perform<T: APIRequest>(
        _ request: URLRequest,
        as _: T.Type,
        didRetryAfterRefresh: Bool
    ) async throws -> T.Response {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw NetworkError.url(error)
        } catch {
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if http.statusCode == 401 {
            if didRetryAfterRefresh {
                await security.clearTokens()
                throw NetworkError.unauthorized
            }

            let hadAuthHeader = request.value(forHTTPHeaderField: "Authorization") != nil
            guard hadAuthHeader else {
                throw NetworkError.unauthorized
            }

            do {
                try await refreshGate.refreshIfNeeded {
                    try await self.security.refreshAccessToken()
                }
            } catch {
                await security.clearTokens()
                throw NetworkError.unauthorized
            }

            guard let newToken = await security.getAccessToken() else {
                await security.clearTokens()
                throw NetworkError.unauthorized
            }

            var retry = request
            retry.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return try await perform(retry, as: T.self, didRetryAfterRefresh: true)
        }

        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpStatus(code: http.statusCode, data: data)
        }

        guard !data.isEmpty else {
            throw NetworkError.noData
        }

        do {
            return try decoder.decode(T.Response.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
