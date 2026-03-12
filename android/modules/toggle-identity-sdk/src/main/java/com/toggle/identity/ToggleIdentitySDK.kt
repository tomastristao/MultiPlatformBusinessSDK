package com.toggle.identity

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object ToggleIdentitySDKConfig {
    const val baseUrl: String = "http://localhost:9011"
}

data class SendMagicLinkRequest(
    val email: String,
    val purpose: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): SendMagicLinkRequest {
                        val email = json.getString("email")
            val purpose = json.getString("purpose")
            return SendMagicLinkRequest(email, purpose)
        }
    }
}

data class SendMagicLinkResponse(
    val message: String,
    val email: String,
    val purpose: String,
    val expiresIn: Int,
    val notificationStatus: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): SendMagicLinkResponse {
                        val message = json.getString("message")
            val email = json.getString("email")
            val purpose = json.getString("purpose")
            val expiresIn = json.getInt("expiresIn")
            val notificationStatus = json.getString("notificationStatus")
            return SendMagicLinkResponse(message, email, purpose, expiresIn, notificationStatus)
        }
    }
}

data class ApiResponseSendMagicLink(
    val success: Boolean,
    val status: Int,
    val message: String,
    val data: SendMagicLinkResponse,
    val error: ErrorDetails,
    val timestamp: String,
    val traceId: String,
    val version: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): ApiResponseSendMagicLink {
                        val success = json.getBoolean("success")
            val status = json.getInt("status")
            val message = json.getString("message")
            val data = SendMagicLinkResponse.fromJson(json.getJSONObject("data"))
            val error = ErrorDetails.fromJson(json.getJSONObject("error"))
            val timestamp = json.getString("timestamp")
            val traceId = json.getString("traceId")
            val version = json.getString("version")
            return ApiResponseSendMagicLink(success, status, message, data, error, timestamp, traceId, version)
        }
    }
}

data class VerifyMagicLinkRequest(
    val email: String,
    val oobCode: String,
    val purpose: String,
    val deviceInfo: DeviceInfo
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): VerifyMagicLinkRequest {
                        val email = json.getString("email")
            val oobCode = json.getString("oobCode")
            val purpose = json.getString("purpose")
            val deviceInfo = DeviceInfo.fromJson(json.getJSONObject("deviceInfo"))
            return VerifyMagicLinkRequest(email, oobCode, purpose, deviceInfo)
        }
    }
}

data class DeviceInfo(
    val deviceId: String,
    val platform: String,
    val appVersion: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): DeviceInfo {
                        val deviceId = json.getString("deviceId")
            val platform = json.getString("platform")
            val appVersion = json.getString("appVersion")
            return DeviceInfo(deviceId, platform, appVersion)
        }
    }
}

data class VerifyMagicLinkResponse(
    val idToken: String,
    val refreshToken: String,
    val tokenType: String,
    val expiresIn: Int,
    val user: UserInfo
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): VerifyMagicLinkResponse {
                        val idToken = json.getString("idToken")
            val refreshToken = json.getString("refreshToken")
            val tokenType = json.getString("tokenType")
            val expiresIn = json.getInt("expiresIn")
            val user = UserInfo.fromJson(json.getJSONObject("user"))
            return VerifyMagicLinkResponse(idToken, refreshToken, tokenType, expiresIn, user)
        }
    }
}

data class UserInfo(
    val userId: String,
    val email: String,
    val status: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): UserInfo {
                        val userId = json.getString("userId")
            val email = json.getString("email")
            val status = json.getString("status")
            return UserInfo(userId, email, status)
        }
    }
}

data class ApiResponseVerifyMagicLink(
    val success: Boolean,
    val status: Int,
    val message: String,
    val data: VerifyMagicLinkResponse,
    val error: ErrorDetails,
    val timestamp: String,
    val traceId: String,
    val version: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): ApiResponseVerifyMagicLink {
                        val success = json.getBoolean("success")
            val status = json.getInt("status")
            val message = json.getString("message")
            val data = VerifyMagicLinkResponse.fromJson(json.getJSONObject("data"))
            val error = ErrorDetails.fromJson(json.getJSONObject("error"))
            val timestamp = json.getString("timestamp")
            val traceId = json.getString("traceId")
            val version = json.getString("version")
            return ApiResponseVerifyMagicLink(success, status, message, data, error, timestamp, traceId, version)
        }
    }
}

data class ErrorDetails(
    val code: String,
    val details: String,
    val fieldErrors: List<FieldError>,
    val helpUrl: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): ErrorDetails {
                        val code = json.getString("code")
            val details = json.getString("details")
            val fieldErrorsArray = json.getJSONArray("fieldErrors")
                        val fieldErrors = buildList {
                            for (index in 0 until fieldErrorsArray.length()) {
                                add(FieldError.fromJson(fieldErrorsArray.getJSONObject(index)))
                            }
                        }
            val helpUrl = json.getString("helpUrl")
            return ErrorDetails(code, details, fieldErrors, helpUrl)
        }
    }
}

data class FieldError(
    val field: String,
    val rejectedValue: String,
    val message: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): FieldError {
                        val field = json.getString("field")
            val rejectedValue = json.getString("rejectedValue")
            val message = json.getString("message")
            return FieldError(field, rejectedValue, message)
        }
    }
}


private class IdentityRepositorySendMagicLinkRequest() : ApiRequest<ApiResponseSendMagicLink> {
    override val path: String = "/api/v1/identity/send-magic-link"
    override val method: HttpMethod = HttpMethod.POST
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json", "Content-Type" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): ApiResponseSendMagicLink =
        ApiResponseSendMagicLink.fromJson(org.json.JSONObject(payload) as org.json.JSONObject)
}

private class IdentityRepositoryVerifyMagicLinkRequest() : ApiRequest<ApiResponseVerifyMagicLink> {
    override val path: String = "/api/v1/identity/verify-magic-link"
    override val method: HttpMethod = HttpMethod.POST
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json", "Content-Type" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): ApiResponseVerifyMagicLink =
        ApiResponseVerifyMagicLink.fromJson(org.json.JSONObject(payload) as org.json.JSONObject)
}


interface IdentityRepositoryProtocol {
    suspend fun sendMagicLink(): ApiResponseSendMagicLink
    suspend fun verifyMagicLink(): ApiResponseVerifyMagicLink
}

class IdentityRepository(
    private val networkEngine: NetworkEngine
) : IdentityRepositoryProtocol {
override suspend fun sendMagicLink(): ApiResponseSendMagicLink {
    return networkEngine.request(IdentityRepositorySendMagicLinkRequest())
}

override suspend fun verifyMagicLink(): ApiResponseVerifyMagicLink {
    return networkEngine.request(IdentityRepositoryVerifyMagicLinkRequest())
}

}


interface ToggleIdentitySDKClientProtocol {
    val identityRepository: IdentityRepositoryProtocol
}

class ToggleIdentitySDKClient(
    networkEngine: NetworkEngine = NetworkEngine(baseUrl = ToggleIdentitySDKConfig.baseUrl)
) : ToggleIdentitySDKClientProtocol {
    override val identityRepository: IdentityRepositoryProtocol = IdentityRepository(networkEngine)
}
