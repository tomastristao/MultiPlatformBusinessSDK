package com.multiplatformbusinesssdk.openbrewery

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object OpenBrewerySDKConfig {
    const val baseUrl: String = "https://api.openbrewerydb.org/v1"
}

data class BrewerySummary(
    val id: String,
    val name: String,
    val brewery_type: String,
    val city: String,
    val state: String,
    val country: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): BrewerySummary {
                        val id = json.getString("id")
            val name = json.getString("name")
            val brewery_type = json.getString("brewery_type")
            val city = json.getString("city")
            val state = json.getString("state")
            val country = json.getString("country")
            return BrewerySummary(id, name, brewery_type, city, state, country)
        }
    }
}

data class BreweryDetailResponse(
    val id: String,
    val name: String,
    val brewery_type: String,
    val address_1: String,
    val city: String,
    val state_province: String,
    val postal_code: String,
    val country: String,
    val phone: String,
    val website_url: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): BreweryDetailResponse {
                        val id = json.getString("id")
            val name = json.getString("name")
            val brewery_type = json.getString("brewery_type")
            val address_1 = json.getString("address_1")
            val city = json.getString("city")
            val state_province = json.getString("state_province")
            val postal_code = json.getString("postal_code")
            val country = json.getString("country")
            val phone = json.getString("phone")
            val website_url = json.getString("website_url")
            return BreweryDetailResponse(id, name, brewery_type, address_1, city, state_province, postal_code, country, phone, website_url)
        }
    }
}


private class BreweryRepositoryFetchBreweriesTestRequest(private val by_city: String, private val per_page: Int = 10) : ApiRequest<List<BrewerySummary>> {
    override val path: String = "/breweries"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = mapOf(
            "by_city" to by_city,
            "per_page" to per_page.toString()
        )
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): List<BrewerySummary> =
        run {
    val items = org.json.JSONArray(payload).let { payload ->
        when (payload) {
            is org.json.JSONArray -> payload
            is org.json.JSONObject -> payload.getJSONArray("data")
            else -> throw IllegalArgumentException("Unsupported JSON payload")
        }
    }
    buildList {
        for (index in 0 until items.length()) {
            add(BrewerySummary.fromJson(items.getJSONObject(index)))
        }
    }
}
}

private class BreweryRepositoryFetchBreweryDetailRequest(private val id: String) : ApiRequest<BreweryDetailResponse> {
    override val path: String = "/breweries/$id"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): BreweryDetailResponse =
        BreweryDetailResponse.fromJson(org.json.JSONObject(payload) as org.json.JSONObject)
}


interface BreweryRepositoryProtocol {
    suspend fun fetchBreweriesTest(by_city: String, per_page: Int): List<BrewerySummary>
    suspend fun fetchBreweryDetail(id: String): BreweryDetailResponse
}

class BreweryRepository(
    private val networkEngine: NetworkEngine
) : BreweryRepositoryProtocol {
override suspend fun fetchBreweriesTest(by_city: String, per_page: Int): List<BrewerySummary> {
    return networkEngine.request(BreweryRepositoryFetchBreweriesTestRequest(by_city = by_city, per_page = per_page))
}

override suspend fun fetchBreweryDetail(id: String): BreweryDetailResponse {
    return networkEngine.request(BreweryRepositoryFetchBreweryDetailRequest(id = id))
}

}


interface OpenBrewerySDKClientProtocol {
    val breweryRepository: BreweryRepositoryProtocol
}

class OpenBrewerySDKClient(
    networkEngine: NetworkEngine = NetworkEngine(baseUrl = OpenBrewerySDKConfig.baseUrl)
) : OpenBrewerySDKClientProtocol {
    override val breweryRepository: BreweryRepositoryProtocol = BreweryRepository(networkEngine)
}
