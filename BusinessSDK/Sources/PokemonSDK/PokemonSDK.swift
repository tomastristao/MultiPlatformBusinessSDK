import Foundation
import BusinessSDKCore

public enum PokemonSDKConfig {
    public static let baseURL = URL(string: "https://pokeapi.co/api/v2")!
}

public struct PokemonListResponse: Codable, Sendable {
    public let count: Int
    public let results: [PokemonEntry]

    public init(count: Int, results: [PokemonEntry]) {
        self.count = count
        self.results = results
    }
}

public struct PokemonEntry: Codable, Sendable {
    public let name: String
    public let url: String

    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

public struct PokemonDetailResponse: Codable, Sendable {
    public let id: Int
    public let name: String
    public let height: Int
    public let weight: Int

    public init(id: Int, name: String, height: Int, weight: Int) {
        self.id = id
        self.name = name
        self.height = height
        self.weight = weight
    }
}


private struct PokemonRepositoryFetchPokemonListRequest: APIRequest {
    private let limit: Int
    private let offset: Int

    init(limit: Int = 20, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/pokemon"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "limit", value: String(describing: limit)), URLQueryItem(name: "offset", value: String(describing: offset))]
    }

    typealias Response = PokemonListResponse
}

private struct PokemonRepositoryFetchPokemonDetailRequest: APIRequest {
    private let name: String

    init(name: String) {
        self.name = name
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/pokemon/\(name)"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = PokemonDetailResponse
}


public protocol PokemonRepositoryProtocol: Sendable {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse
    func fetchPokemonDetail(name: String) async throws -> PokemonDetailResponse
}

public final class PokemonRepository: PokemonRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func fetchPokemonList(limit: Int = 20, offset: Int = 0) async throws -> PokemonListResponse {
    try await networkEngine.request(PokemonRepositoryFetchPokemonListRequest(limit: limit, offset: offset))
}

public func fetchPokemonDetail(name: String) async throws -> PokemonDetailResponse {
    try await networkEngine.request(PokemonRepositoryFetchPokemonDetailRequest(name: name))
}

}


public protocol PokemonSDKClientProtocol: Sendable {
    var pokemonRepository: PokemonRepositoryProtocol { get }
}

public struct PokemonSDKClient: PokemonSDKClientProtocol, Sendable {
    public let pokemonRepository: PokemonRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: PokemonSDKConfig.baseURL)) {
        self.pokemonRepository = PokemonRepository(networkEngine: networkEngine)
    }
}
