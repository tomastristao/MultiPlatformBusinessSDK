import Foundation
import BusinessSDKCore

public enum ToggleIdentitySDKConfig {
    public static let baseURL = URL(string: "http://localhost:9011")!
}

public struct SendMagicLinkRequest: Codable, Sendable {
    public let email: String
    public let purpose: String

    public init(email: String, purpose: String) {
        self.email = email
        self.purpose = purpose
    }
}

public struct SendMagicLinkResponse: Codable, Sendable {
    public let message: String
    public let email: String
    public let purpose: String
    public let expiresIn: Int
    public let notificationStatus: String

    public init(message: String, email: String, purpose: String, expiresIn: Int, notificationStatus: String) {
        self.message = message
        self.email = email
        self.purpose = purpose
        self.expiresIn = expiresIn
        self.notificationStatus = notificationStatus
    }
}

public struct ApiResponseSendMagicLink: Codable, Sendable {
    public let success: Bool
    public let status: Int
    public let message: String
    public let data: SendMagicLinkResponse
    public let error: ErrorDetails
    public let timestamp: String
    public let traceId: String
    public let version: String

    public init(success: Bool, status: Int, message: String, data: SendMagicLinkResponse, error: ErrorDetails, timestamp: String, traceId: String, version: String) {
        self.success = success
        self.status = status
        self.message = message
        self.data = data
        self.error = error
        self.timestamp = timestamp
        self.traceId = traceId
        self.version = version
    }
}

public struct VerifyMagicLinkRequest: Codable, Sendable {
    public let email: String
    public let oobCode: String
    public let purpose: String
    public let deviceInfo: DeviceInfo

    public init(email: String, oobCode: String, purpose: String, deviceInfo: DeviceInfo) {
        self.email = email
        self.oobCode = oobCode
        self.purpose = purpose
        self.deviceInfo = deviceInfo
    }
}

public struct DeviceInfo: Codable, Sendable {
    public let deviceId: String
    public let platform: String
    public let appVersion: String

    public init(deviceId: String, platform: String, appVersion: String) {
        self.deviceId = deviceId
        self.platform = platform
        self.appVersion = appVersion
    }
}

public struct VerifyMagicLinkResponse: Codable, Sendable {
    public let idToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let user: UserInfo

    public init(idToken: String, refreshToken: String, tokenType: String, expiresIn: Int, user: UserInfo) {
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.user = user
    }
}

public struct UserInfo: Codable, Sendable {
    public let userId: String
    public let email: String
    public let status: String

    public init(userId: String, email: String, status: String) {
        self.userId = userId
        self.email = email
        self.status = status
    }
}

public struct ApiResponseVerifyMagicLink: Codable, Sendable {
    public let success: Bool
    public let status: Int
    public let message: String
    public let data: VerifyMagicLinkResponse
    public let error: ErrorDetails
    public let timestamp: String
    public let traceId: String
    public let version: String

    public init(success: Bool, status: Int, message: String, data: VerifyMagicLinkResponse, error: ErrorDetails, timestamp: String, traceId: String, version: String) {
        self.success = success
        self.status = status
        self.message = message
        self.data = data
        self.error = error
        self.timestamp = timestamp
        self.traceId = traceId
        self.version = version
    }
}

public struct ErrorDetails: Codable, Sendable {
    public let code: String
    public let details: String
    public let fieldErrors: [FieldError]
    public let helpUrl: String

    public init(code: String, details: String, fieldErrors: [FieldError], helpUrl: String) {
        self.code = code
        self.details = details
        self.fieldErrors = fieldErrors
        self.helpUrl = helpUrl
    }
}

public struct FieldError: Codable, Sendable {
    public let field: String
    public let rejectedValue: String
    public let message: String

    public init(field: String, rejectedValue: String, message: String) {
        self.field = field
        self.rejectedValue = rejectedValue
        self.message = message
    }
}


private struct IdentityRepositorySendMagicLinkRequest: APIRequest {


    init() {

    }

    let method: HTTPMethod = .post
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json", "Content-Type": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/api/v1/identity/send-magic-link"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = ApiResponseSendMagicLink
}

private struct IdentityRepositoryVerifyMagicLinkRequest: APIRequest {


    init() {

    }

    let method: HTTPMethod = .post
    let body: Data? = nil
    let headers: [String: String] = ["Accept": "application/json", "Content-Type": "application/json"]
    let requiresAuthorization: Bool = false

    var path: String {
        "/api/v1/identity/verify-magic-link"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    typealias Response = ApiResponseVerifyMagicLink
}


public protocol IdentityRepositoryProtocol: Sendable {
    func sendMagicLink() async throws -> ApiResponseSendMagicLink
    func verifyMagicLink() async throws -> ApiResponseVerifyMagicLink
}

public final class IdentityRepository: IdentityRepositoryProtocol, @unchecked Sendable {
    private let networkEngine: NetworkEngineProtocol

    public init(networkEngine: NetworkEngineProtocol) {
        self.networkEngine = networkEngine
    }

public func sendMagicLink() async throws -> ApiResponseSendMagicLink {
    try await networkEngine.request(IdentityRepositorySendMagicLinkRequest())
}

public func verifyMagicLink() async throws -> ApiResponseVerifyMagicLink {
    try await networkEngine.request(IdentityRepositoryVerifyMagicLinkRequest())
}

}


public protocol ToggleIdentitySDKClientProtocol: Sendable {
    var identityRepository: IdentityRepositoryProtocol { get }
}

public struct ToggleIdentitySDKClient: ToggleIdentitySDKClientProtocol, Sendable {
    public let identityRepository: IdentityRepositoryProtocol

    public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: ToggleIdentitySDKConfig.baseURL)) {
        self.identityRepository = IdentityRepository(networkEngine: networkEngine)
    }
}
