package com.multiplatformbusinesssdk.rickandmorty

import com.multiplatformbusinesssdk.core.ApiRequest
import com.multiplatformbusinesssdk.core.HttpMethod
import com.multiplatformbusinesssdk.core.NetworkEngine

object RickAndMortySDKConfig {
    const val baseUrl: String = "https://rickandmortyapi.com/api"
}

data class CharacterListResponse(
    val info: PageInfo,
    val results: List<CharacterSummary>
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): CharacterListResponse {
                        val info = PageInfo.fromJson(json.getJSONObject("info"))
            val resultsArray = json.getJSONArray("results")
                        val results = buildList {
                            for (index in 0 until resultsArray.length()) {
                                add(CharacterSummary.fromJson(resultsArray.getJSONObject(index)))
                            }
                        }
            return CharacterListResponse(info, results)
        }
    }
}

data class PageInfo(
    val count: Int,
    val pages: Int,
    val next: String,
    val prev: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): PageInfo {
                        val count = json.getInt("count")
            val pages = json.getInt("pages")
            val next = json.getString("next")
            val prev = json.getString("prev")
            return PageInfo(count, pages, next, prev)
        }
    }
}

data class CharacterSummary(
    val id: Int,
    val name: String,
    val status: String,
    val species: String,
    val image: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): CharacterSummary {
                        val id = json.getInt("id")
            val name = json.getString("name")
            val status = json.getString("status")
            val species = json.getString("species")
            val image = json.getString("image")
            return CharacterSummary(id, name, status, species, image)
        }
    }
}

data class CharacterDetailResponse(
    val id: Int,
    val name: String,
    val status: String,
    val species: String,
    val gender: String,
    val image: String
) {
    companion object {
        fun fromJson(json: org.json.JSONObject): CharacterDetailResponse {
                        val id = json.getInt("id")
            val name = json.getString("name")
            val status = json.getString("status")
            val species = json.getString("species")
            val gender = json.getString("gender")
            val image = json.getString("image")
            return CharacterDetailResponse(id, name, status, species, gender, image)
        }
    }
}


private class CharacterRepositoryFetchCharactersRequest(private val page: Int = 1) : ApiRequest<CharacterListResponse> {
    override val path: String = "/character"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = mapOf(
            "page" to page.toString()
        )
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): CharacterListResponse =
        CharacterListResponse.fromJson(org.json.JSONObject(payload))
}

private class CharacterRepositoryFetchCharacterDetailRequest(private val id: Int) : ApiRequest<CharacterDetailResponse> {
    override val path: String = "/character/$id"
    override val method: HttpMethod = HttpMethod.GET
    override val body: ByteArray? = null
    override val headers: Map<String, String> = mapOf("Accept" to "application/json")
    override val query: Map<String, String> = emptyMap()
    override val requiresAuthorization: Boolean = false

    override fun parse(payload: String): CharacterDetailResponse =
        CharacterDetailResponse.fromJson(org.json.JSONObject(payload))
}


interface CharacterRepositoryProtocol {
    suspend fun fetchCharacters(page: Int): CharacterListResponse
    suspend fun fetchCharacterDetail(id: Int): CharacterDetailResponse
}

class CharacterRepository(
    private val networkEngine: NetworkEngine
) : CharacterRepositoryProtocol {
override suspend fun fetchCharacters(page: Int): CharacterListResponse {
    return networkEngine.request(CharacterRepositoryFetchCharactersRequest(page = page))
}

override suspend fun fetchCharacterDetail(id: Int): CharacterDetailResponse {
    return networkEngine.request(CharacterRepositoryFetchCharacterDetailRequest(id = id))
}

}


interface RickAndMortySDKClientProtocol {
    val characterRepository: CharacterRepositoryProtocol
}

class RickAndMortySDKClient(
    networkEngine: NetworkEngine = NetworkEngine(baseUrl = RickAndMortySDKConfig.baseUrl)
) : RickAndMortySDKClientProtocol {
    override val characterRepository: CharacterRepositoryProtocol = CharacterRepository(networkEngine)
}
