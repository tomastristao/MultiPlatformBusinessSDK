# MultiPlatformBusinessSDK

Contract-driven SDK generation for iOS and Android business logic.

## What lives here

- `contracts/*.yml`: API contracts that define models, repositories, and endpoints.
- `scripts/generate_sdks.rb`: Regenerates both platform SDKs from those contracts.
- `BusinessSDK/`: Swift Package Manager package with a shared native Swift network layer plus generated repositories.
- `android/`: Android library modules with a native Kotlin network layer plus generated repositories.
- `docs/generated/SDK_CATALOG.md`: Generated contract and repository catalog.
- `.github/workflows/generate-sdks.yml`: Regenerates committed SDK code whenever contract YAML files change on push and publishes an emoji-based workflow summary.

## Example contract

The repo stays empty by default. A sample Pokemon contract is kept as a test fixture at `test/fixtures/pokemon.yml` and defines:

- `fetchPokemonList(limit:offset:)`
- `fetchPokemonDetail(name:)`

The generated repository API is intentionally aligned across Swift and Kotlin.

## Generate

```bash
ruby scripts/generate_sdks.rb
```

With no files in `contracts/`, generation keeps the SDK empty and only emits the shared native networking core.
It also refreshes `docs/generated/SDK_CATALOG.md`.

## Tests

```bash
ruby test/generator_test.rb
```

This verifies both:

- the empty baseline generates no feature SDKs
- adding the Pokemon fixture contract generates repository output for Swift and Android

## iOS usage

```swift
import BusinessSDK

let engine = NetworkEngine(baseURL: URL(string: "https://api.example.com")!)
```

## Android usage

```kotlin
import com.multiplatformbusinesssdk.core.NetworkEngine
val engine = NetworkEngine(baseUrl = "https://api.example.com")
```

## Add a new API

1. Add a new YAML contract in `contracts/`, for example by copying `test/fixtures/pokemon.yml`.
2. Run `ruby scripts/generate_sdks.rb`.
3. Commit the generated changes in `BusinessSDK/`, `android/`, and `docs/generated/`.

On GitHub, pushes that touch contract YAML files trigger the regeneration workflow automatically. The workflow uses emoji-labelled steps and writes an emoji summary to the Actions run page showing changed contracts and generated outputs.
