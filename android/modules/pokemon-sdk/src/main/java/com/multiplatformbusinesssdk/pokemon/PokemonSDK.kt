package com.multiplatformbusinesssdk.pokemon

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object PokemonSDKConfig {
    const val baseUrl: String = "https://pokeapi.co/api/v2"
}

data class PokemonListResponse(
    val count: Int,
    val results: List<PokemonEntry>
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): PokemonListResponse {
                        val count = json.getInt("count")
            val resultsArray = json.getJSONArray("results")
                        val results = buildList {
                            for (index in 0 until resultsArray.length()) {
                                add(PokemonEntry.fromJson(resultsArray.getJSONObject(index)))
                            }
                        }
            return PokemonListResponse(count, results)
        }
    }
}

data class PokemonEntry(
    val name: String,
    val url: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): PokemonEntry {
                        val name = json.getString("name")
            val url = json.getString("url")
            return PokemonEntry(name, url)
        }
    }
}

data class PokemonDetailResponse(
    val id: Int,
    val name: String,
    val height: Int,
    val weight: Int
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): PokemonDetailResponse {
                        val id = json.getInt("id")
            val name = json.getString("name")
            val height = json.getInt("height")
            val weight = json.getInt("weight")
            return PokemonDetailResponse(id, name, height, weight)
        }
    }
}


private class FetchPokemonListRequest(private val limit: Int = 20, private val offset: Int = 0) : ApiRequest<PokemonListResponse> {
    override val path: String = "/pokemon"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = mapOf(
            "limit" to limit.toString(),
            "offset" to offset.toString()
        )
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): PokemonListResponse =
        PokemonListResponse.fromJson(org.json.JSONObject(payload))
}

private class FetchPokemonDetailRequest(private val name: String) : ApiRequest<PokemonDetailResponse> {
    override val path: String = "/pokemon/$name"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): PokemonDetailResponse =
        PokemonDetailResponse.fromJson(org.json.JSONObject(payload))
}


interface PokemonRepository {
    suspend fun fetchPokemonList(limit: Int = 20, offset: Int = 0): PokemonListResponse
    suspend fun fetchPokemonDetail(name: String): PokemonDetailResponse
}

class DefaultPokemonRepository(
    private val networkEngine: NetworkEngine
) : PokemonRepository {
override suspend fun fetchPokemonList(limit: Int = 20, offset: Int = 0): PokemonListResponse {
    return networkEngine.request(FetchPokemonListRequest(limit = limit, offset = offset))
}

override suspend fun fetchPokemonDetail(name: String): PokemonDetailResponse {
    return networkEngine.request(FetchPokemonDetailRequest(name = name))
}

}
