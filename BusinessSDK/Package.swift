// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BusinessSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BusinessSDK",
            targets: ["BusinessSDK"]
        ),
        .library(
            name: "AdviceSlipSDK",
            targets: ["AdviceSlipSDK"]
        ),
        .library(
            name: "CatFactsSDK",
            targets: ["CatFactsSDK"]
        ),
        .library(
            name: "PokemonSDK",
            targets: ["PokemonSDK"]
        ),
        .library(
            name: "RickAndMortySDK",
            targets: ["RickAndMortySDK"]
        ),
    ],
    targets: [
        .target(
            name: "BusinessSDKCore"
        ),
        .target(
            name: "AdviceSlipSDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .target(
            name: "CatFactsSDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .target(
            name: "PokemonSDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .target(
            name: "RickAndMortySDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .target(
            name: "BusinessSDK",
            dependencies: ["BusinessSDKCore", "AdviceSlipSDK", "CatFactsSDK", "PokemonSDK", "RickAndMortySDK"]
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK", "AdviceSlipSDK", "CatFactsSDK", "PokemonSDK", "RickAndMortySDK"]
        )
    ]
)
