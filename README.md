# MultiPlatformBusinessSDK

Contract-driven SDK generation for iOS and Android business logic.

## What lives here

- `contracts/*.yml`: API contracts that define models, repositories, and endpoints.
- `scripts/generate_sdks.rb`: Regenerates both platform SDKs from those contracts.
- `BusinessSDK/`: Swift Package Manager package with a shared native Swift network layer plus generated repositories.
- `android/`: Android library modules with a native Kotlin network layer plus generated repositories.
- `.github/workflows/generate-sdks.yml`: Regenerates committed SDK code whenever contract YAML files change on push.

## Example contract

`contracts/pokemon.yml` defines a Pokemon repository with:

- `fetchPokemonList(limit:offset:)`
- `fetchPokemonDetail(name:)`

The generated repository API is intentionally aligned across Swift and Kotlin.

## Generate

```bash
ruby scripts/generate_sdks.rb
```

## iOS usage

```swift
import BusinessSDK

let engine = NetworkEngine(baseURL: PokemonSDKConfig.baseURL)
let repository = PokemonRepository(networkEngine: engine)
let page = try await repository.fetchPokemonList()
```

## Android usage

```kotlin
import com.multiplatformbusinesssdk.core.NetworkEngine
import com.multiplatformbusinesssdk.pokemon.DefaultPokemonRepository
import com.multiplatformbusinesssdk.pokemon.PokemonSDKConfig

val engine = NetworkEngine(baseUrl = PokemonSDKConfig.baseUrl)
val repository = DefaultPokemonRepository(engine)
val page = repository.fetchPokemonList()
```

## Add a new API

1. Add a new YAML contract in `contracts/`.
2. Run `ruby scripts/generate_sdks.rb`.
3. Commit the generated changes in `BusinessSDK/` and `android/`.

On GitHub, pushes that touch contract YAML files trigger the regeneration workflow automatically.
