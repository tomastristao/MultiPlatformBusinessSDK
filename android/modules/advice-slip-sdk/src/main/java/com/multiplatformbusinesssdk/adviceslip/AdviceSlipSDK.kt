package com.multiplatformbusinesssdk.adviceslip

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object AdviceSlipSDKConfig {
    const val baseUrl: String = "https://api.adviceslip.com"
}

data class AdviceEnvelope(
    val slip: AdviceSlip
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): AdviceEnvelope {
                        val slip = AdviceSlip.fromJson(json.getJSONObject("slip"))
            return AdviceEnvelope(slip)
        }
    }
}

data class AdviceSlip(
    val id: Int,
    val advice: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): AdviceSlip {
                        val id = json.getInt("id")
            val advice = json.getString("advice")
            return AdviceSlip(id, advice)
        }
    }
}


private class AdviceRepositoryFetchRandomAdviceRequest() : ApiRequest<AdviceEnvelope> {
    override val path: String = "/advice"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): AdviceEnvelope =
        AdviceEnvelope.fromJson(org.json.JSONObject(payload) as org.json.JSONObject)
}

private class AdviceRepositoryFetchAdviceByIdRequest(private val id: Int) : ApiRequest<AdviceEnvelope> {
    override val path: String = "/advice/$id"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): AdviceEnvelope =
        AdviceEnvelope.fromJson(org.json.JSONObject(payload) as org.json.JSONObject)
}


interface AdviceRepositoryProtocol {
    suspend fun fetchRandomAdvice(): AdviceEnvelope
    suspend fun fetchAdviceById(id: Int): AdviceEnvelope
}

class AdviceRepository(
    private val networkEngine: NetworkEngine
) : AdviceRepositoryProtocol {
override suspend fun fetchRandomAdvice(): AdviceEnvelope {
    return networkEngine.request(AdviceRepositoryFetchRandomAdviceRequest())
}

override suspend fun fetchAdviceById(id: Int): AdviceEnvelope {
    return networkEngine.request(AdviceRepositoryFetchAdviceByIdRequest(id = id))
}

}


interface AdviceSlipSDKClientProtocol {
    val adviceRepository: AdviceRepositoryProtocol
}

class AdviceSlipSDKClient(
    networkEngine: NetworkEngine = NetworkEngine(baseUrl = AdviceSlipSDKConfig.baseUrl)
) : AdviceSlipSDKClientProtocol {
    override val adviceRepository: AdviceRepositoryProtocol = AdviceRepository(networkEngine)
}
