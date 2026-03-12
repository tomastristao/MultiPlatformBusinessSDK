import Foundation
import BusinessSDKCore

public enum RickAndMortySDKConfig {
    public static let baseURL = URL(string: "https://rickandmortyapi.com/api")!
}

public struct CharacterListResponse: Codable, Sendable {
    public let info: PageInfo
    public let results: [CharacterSummary]

    public init(info: PageInfo, results: [CharacterSummary]) {
        self.info = info
        self.results = results
    }
}

public struct PageInfo: Codable, Sendable {
    public let count: Int
    public let pages: Int
    public let next: String
    public let prev: String

    public init(count: Int, pages: Int, next: String, prev: String) {
        self.count = count
        self.pages = pages
        self.next = next
        self.prev = prev
    }
}

public struct CharacterSummary: Codable, Sendable {
    public let id: Int
    public let name: String
    public let status: String
    public let species: String
    public let image: String

    public init(id: Int, name: String, status: String, species: String, image: String) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.image = image
    }
}

public struct CharacterDetailResponse: Codable, Sendable {
    public let id: Int
    public let name: String
    public let status: String
    public let species: String
    public let gender: String
    public let image: String

    public init(id: Int, name: String, status: String, species: String, gender: String, image: String) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.gender = gender
        self.image = image
    }
}


private struct CharacterRepositoryFetchCharactersRequest: APIRequest {
    private let page: Int

    init(page: Int = 1) {
        self.page = page
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/character"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(describing: page))]
    }

    typealias Response = CharacterListResponse
}

private struct CharacterRepositoryFetchCharacterDetailRequest: APIRequest {
    private let id: Int

    init(id: Int) {
        self.id = id
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/character/\(id)"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = CharacterDetailResponse
}


public protocol CharacterRepositoryProtocol: Sendable {
    func fetchCharacters(page: Int) async throws -> CharacterListResponse
    func fetchCharacterDetail(id: Int) async throws -> CharacterDetailResponse
}

public final class CharacterRepository: CharacterRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func fetchCharacters(page: Int = 1) async throws -> CharacterListResponse {
    try await networkEngine.request(CharacterRepositoryFetchCharactersRequest(page: page))
}

public func fetchCharacterDetail(id: Int) async throws -> CharacterDetailResponse {
    try await networkEngine.request(CharacterRepositoryFetchCharacterDetailRequest(id: id))
}

}


public protocol RickAndMortySDKClientProtocol: Sendable {
    var characterRepository: CharacterRepositoryProtocol { get }
}

public struct RickAndMortySDKClient: RickAndMortySDKClientProtocol, Sendable {
    public let characterRepository: CharacterRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: RickAndMortySDKConfig.baseURL)) {
        self.characterRepository = CharacterRepository(networkEngine: networkEngine)
    }
}
