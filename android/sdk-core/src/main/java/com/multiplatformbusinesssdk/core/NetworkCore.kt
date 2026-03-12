package com.multiplatformbusinesssdk.core

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

enum class HttpMethod {
    GET,
    POST,
    PUT,
    DELETE
}

sealed class NetworkError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class Url(cause: IOException) : NetworkError("URL error", cause)
    object InvalidResponse : NetworkError("Invalid HTTP response")
    object Unauthorized : NetworkError("Unauthorized")
    class HttpStatus(val code: Int, val payload: String) : NetworkError("Unexpected status: $code")
    object NoData : NetworkError("No data returned")
    class Decoding(cause: Throwable) : NetworkError("Decoding failed", cause)
}

interface TokenStore {
    suspend fun getAccessToken(): String?
    suspend fun refreshAccessToken()
    suspend fun clearTokens()
}

object NoOpTokenStore : TokenStore {
    override suspend fun getAccessToken(): String? = null
    override suspend fun refreshAccessToken() = Unit
    override suspend fun clearTokens() = Unit
}

class RefreshGate {
    private val mutex = Mutex()

    suspend fun refreshIfNeeded(operation: suspend () -> Unit) {
        mutex.withLock {
            operation()
        }
    }
}

interface ApiRequest<T> {
    val path: String
    val method: HttpMethod
    val body: ByteArray?
    val headers: Map<String, String>
    val query: Map<String, String>
    val requiresAuthorization: Boolean

    fun parse(payload: String): T
}

class NetworkEngine(
    private val baseUrl: String,
    private val tokenStore: TokenStore = NoOpTokenStore,
    private val refreshGate: RefreshGate = RefreshGate()
) {
    suspend fun <T> request(requestConfig: ApiRequest<T>): T {
        val url = buildUrl(requestConfig)
        return perform(url, requestConfig, didRetryAfterRefresh = false)
    }

    private suspend fun <T> perform(
        url: URL,
        requestConfig: ApiRequest<T>,
        didRetryAfterRefresh: Boolean
    ): T {
        val connection = (url.openConnection() as? HttpURLConnection) ?: throw NetworkError.InvalidResponse

        try {
            connection.requestMethod = requestConfig.method.name
            connection.instanceFollowRedirects = true
            requestConfig.headers.forEach { (key, value) -> connection.setRequestProperty(key, value) }

            if (requestConfig.requiresAuthorization) {
                tokenStore.getAccessToken()?.let { token ->
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }
            }

            requestConfig.body?.let { body ->
                connection.doOutput = true
                connection.outputStream.use { stream -> stream.write(body) }
            }

            val statusCode = connection.responseCode
            val payload = readPayload(connection, statusCode)

            if (statusCode == 401) {
                if (didRetryAfterRefresh) {
                    tokenStore.clearTokens()
                    throw NetworkError.Unauthorized
                }

                val hadAuthHeader = connection.getRequestProperty("Authorization") != null
                if (!hadAuthHeader) {
                    throw NetworkError.Unauthorized
                }

                try {
                    refreshGate.refreshIfNeeded {
                        tokenStore.refreshAccessToken()
                    }
                } catch (_: Throwable) {
                    tokenStore.clearTokens()
                    throw NetworkError.Unauthorized
                }

                val refreshedToken = tokenStore.getAccessToken() ?: run {
                    tokenStore.clearTokens()
                    throw NetworkError.Unauthorized
                }

                val retryHeaders = requestConfig.headers + mapOf("Authorization" to "Bearer $refreshedToken")
                val retryRequest = object : ApiRequest<T> by requestConfig {
                    override val headers: Map<String, String> = retryHeaders
                }
                return perform(buildUrl(retryRequest), retryRequest, didRetryAfterRefresh = true)
            }

            if (statusCode !in 200..299) {
                throw NetworkError.HttpStatus(statusCode, payload)
            }

            if (payload.isBlank()) {
                throw NetworkError.NoData
            }

            return try {
                requestConfig.parse(payload)
            } catch (error: Throwable) {
                throw NetworkError.Decoding(error)
            }
        } catch (error: IOException) {
            throw NetworkError.Url(error)
        } finally {
            connection.disconnect()
        }
    }

    private fun <T> buildUrl(requestConfig: ApiRequest<T>): URL {
        val normalizedBaseUrl = baseUrl.trimEnd('/')
        val normalizedPath = requestConfig.path.trimStart('/')
        val query = if (requestConfig.query.isEmpty()) {
            ""
        } else {
            requestConfig.query.entries.joinToString(prefix = "?", separator = "&") { (key, value) ->
                "${encode(key)}=${encode(value)}"
            }
        }
        return URL("$normalizedBaseUrl/$normalizedPath$query")
    }

    private fun encode(value: String): String = java.net.URLEncoder.encode(value, Charsets.UTF_8.name())

    private fun readPayload(connection: HttpURLConnection, statusCode: Int): String {
        val stream = if (statusCode in 200..299) connection.inputStream else connection.errorStream
        return stream?.bufferedReader()?.use { it.readText() }.orEmpty()
    }
}
