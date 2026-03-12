import Foundation
import BusinessSDKCore

public enum CatFactsSDKConfig {
    public static let baseURL = URL(string: "https://catfact.ninja")!
}

public struct FactListResponse: Codable, Sendable {
    public let current_page: Int
    public let data: [FactResponse]

    public init(current_page: Int, data: [FactResponse]) {
        self.current_page = current_page
        self.data = data
    }
}

public struct FactResponse: Codable, Sendable {
    public let fact: String
    public let length: Int

    public init(fact: String, length: Int) {
        self.fact = fact
        self.length = length
    }
}


private struct CatFactRepositoryFetchFactsRequest: APIRequest {
    private let limit: Int

    init(limit: Int = 10) {
        self.limit = limit
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/facts"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "limit", value: String(describing: limit))]
    }

    typealias Response = FactListResponse
}

private struct CatFactRepositoryFetchRandomFactRequest: APIRequest {


    init() {

    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/fact"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = FactResponse
}


public protocol CatFactRepositoryProtocol: Sendable {
    func fetchFacts(limit: Int) async throws -> FactListResponse
    func fetchRandomFact() async throws -> FactResponse
}

public final class CatFactRepository: CatFactRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func fetchFacts(limit: Int = 10) async throws -> FactListResponse {
    try await networkEngine.request(CatFactRepositoryFetchFactsRequest(limit: limit))
}

public func fetchRandomFact() async throws -> FactResponse {
    try await networkEngine.request(CatFactRepositoryFetchRandomFactRequest())
}

}


public protocol CatFactsSDKClientProtocol: Sendable {
    var catFactRepository: CatFactRepositoryProtocol { get }
}

public struct CatFactsSDKClient: CatFactsSDKClientProtocol, Sendable {
    public let catFactRepository: CatFactRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: CatFactsSDKConfig.baseURL)) {
        self.catFactRepository = CatFactRepository(networkEngine: networkEngine)
    }
}
