import Foundation
import BusinessSDKCore

public enum OpenBrewerySDKConfig {
    public static let baseURL = URL(string: "https://api.openbrewerydb.org/v1")!
}

public struct BrewerySummary: Codable, Sendable {
    public let id: String
    public let name: String
    public let brewery_type: String
    public let city: String
    public let state: String
    public let country: String

    public init(id: String, name: String, brewery_type: String, city: String, state: String, country: String) {
        self.id = id
        self.name = name
        self.brewery_type = brewery_type
        self.city = city
        self.state = state
        self.country = country
    }
}

public struct BreweryDetailResponse: Codable, Sendable {
    public let id: String
    public let name: String
    public let brewery_type: String
    public let address_1: String
    public let city: String
    public let state_province: String
    public let postal_code: String
    public let country: String
    public let phone: String
    public let website_url: String

    public init(id: String, name: String, brewery_type: String, address_1: String, city: String, state_province: String, postal_code: String, country: String, phone: String, website_url: String) {
        self.id = id
        self.name = name
        self.brewery_type = brewery_type
        self.address_1 = address_1
        self.city = city
        self.state_province = state_province
        self.postal_code = postal_code
        self.country = country
        self.phone = phone
        self.website_url = website_url
    }
}


private struct BreweryRepositoryFetchBreweriesTestRequest: APIRequest {
    private let by_city: String
    private let per_page: Int

    init(by_city: String, per_page: Int = 10) {
        self.by_city = by_city
        self.per_page = per_page
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/breweries"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "by_city", value: String(describing: by_city)), URLQueryItem(name: "per_page", value: String(describing: per_page))]
    }

    typealias Response = [BrewerySummary]
}

private struct BreweryRepositoryFetchBreweryDetailRequest: APIRequest {
    private let id: String

    init(id: String) {
        self.id = id
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/breweries/\(id)"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = BreweryDetailResponse
}


public protocol BreweryRepositoryProtocol: Sendable {
    func fetchBreweriesTest(by_city: String, per_page: Int) async throws -> [BrewerySummary]
    func fetchBreweryDetail(id: String) async throws -> BreweryDetailResponse
}

public final class BreweryRepository: BreweryRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func fetchBreweriesTest(by_city: String, per_page: Int = 10) async throws -> [BrewerySummary] {
    try await networkEngine.request(BreweryRepositoryFetchBreweriesTestRequest(by_city: by_city, per_page: per_page))
}

public func fetchBreweryDetail(id: String) async throws -> BreweryDetailResponse {
    try await networkEngine.request(BreweryRepositoryFetchBreweryDetailRequest(id: id))
}

}


public protocol OpenBrewerySDKClientProtocol: Sendable {
    var breweryRepository: BreweryRepositoryProtocol { get }
}

public struct OpenBrewerySDKClient: OpenBrewerySDKClientProtocol, Sendable {
    public let breweryRepository: BreweryRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: OpenBrewerySDKConfig.baseURL)) {
        self.breweryRepository = BreweryRepository(networkEngine: networkEngine)
    }
}
