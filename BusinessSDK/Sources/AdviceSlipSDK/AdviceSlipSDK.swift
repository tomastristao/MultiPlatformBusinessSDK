import Foundation
import BusinessSDKCore

public enum AdviceSlipSDKConfig {
    public static let baseURL = URL(string: "https://api.adviceslip.com")!
}

public struct AdviceEnvelope: Codable, Sendable {
    public let slip: AdviceSlip

    public init(slip: AdviceSlip) {
        self.slip = slip
    }
}

public struct AdviceSlip: Codable, Sendable {
    public let id: Int
    public let advice: String

    public init(id: Int, advice: String) {
        self.id = id
        self.advice = advice
    }
}


private struct AdviceRepositoryFetchRandomAdviceTESTRequest: APIRequest {


    init() {

    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/advice"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = AdviceEnvelope
}

private struct AdviceRepositoryFetchAdviceByIdRequest: APIRequest {
    private let id: Int

    init(id: Int) {
        self.id = id
    }

    let method: HTTPMethod = .get
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/advice/\(id)"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = AdviceEnvelope
}


public protocol AdviceRepositoryProtocol: Sendable {
    func fetchRandomAdviceTEST() async throws -> AdviceEnvelope
    func fetchAdviceById(id: Int) async throws -> AdviceEnvelope
}

public final class AdviceRepository: AdviceRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func fetchRandomAdviceTEST() async throws -> AdviceEnvelope {
    try await networkEngine.request(AdviceRepositoryFetchRandomAdviceTESTRequest())
}

public func fetchAdviceById(id: Int) async throws -> AdviceEnvelope {
    try await networkEngine.request(AdviceRepositoryFetchAdviceByIdRequest(id: id))
}

}


public protocol AdviceSlipSDKClientProtocol: Sendable {
    var adviceRepository: AdviceRepositoryProtocol { get }
}

public struct AdviceSlipSDKClient: AdviceSlipSDKClientProtocol, Sendable {
    public let adviceRepository: AdviceRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: AdviceSlipSDKConfig.baseURL)) {
        self.adviceRepository = AdviceRepository(networkEngine: networkEngine)
    }
}
