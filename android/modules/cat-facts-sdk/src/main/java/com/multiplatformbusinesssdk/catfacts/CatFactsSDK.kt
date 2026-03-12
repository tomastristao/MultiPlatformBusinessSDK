package com.multiplatformbusinesssdk.catfacts

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object CatFactsSDKConfig {
    const val baseUrl: String = "https://catfact.ninja"
}

data class FactListResponse(
    val current_page: Int,
    val data: List<FactResponse>
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): FactListResponse {
                        val current_page = json.getInt("current_page")
            val dataArray = json.getJSONArray("data")
                        val data = buildList {
                            for (index in 0 until dataArray.length()) {
                                add(FactResponse.fromJson(dataArray.getJSONObject(index)))
                            }
                        }
            return FactListResponse(current_page, data)
        }
    }
}

data class FactResponse(
    val fact: String,
    val length: Int
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): FactResponse {
                        val fact = json.getString("fact")
            val length = json.getInt("length")
            return FactResponse(fact, length)
        }
    }
}


private class CatFactRepositoryFetchFactsRequest(private val limit: Int = 10) : ApiRequest<FactListResponse> {
    override val path: String = "/facts"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = mapOf(
            "limit" to limit.toString()
        )
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): FactListResponse =
        FactListResponse.fromJson(org.json.JSONObject(payload))
}

private class CatFactRepositoryFetchRandomFactRequest() : ApiRequest<FactResponse> {
    override val path: String = "/fact"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): FactResponse =
        FactResponse.fromJson(org.json.JSONObject(payload))
}


interface CatFactRepositoryProtocol {
    suspend fun fetchFacts(limit: Int = 10): FactListResponse
    suspend fun fetchRandomFact(): FactResponse
}

class CatFactRepository(
    private val networkEngine: NetworkEngine
) : CatFactRepositoryProtocol {
override suspend fun fetchFacts(limit: Int = 10): FactListResponse {
    return networkEngine.request(CatFactRepositoryFetchFactsRequest(limit = limit))
}

override suspend fun fetchRandomFact(): FactResponse {
    return networkEngine.request(CatFactRepositoryFetchRandomFactRequest())
}

}


interface CatFactsSDKClientProtocol {
    val catFactRepository: CatFactRepositoryProtocol
}

class CatFactsSDKClient(
    networkEngine: NetworkEngine = NetworkEngine(baseUrl = CatFactsSDKConfig.baseUrl)
) : CatFactsSDKClientProtocol {
    override val catFactRepository: CatFactRepositoryProtocol = CatFactRepository(networkEngine)
}
