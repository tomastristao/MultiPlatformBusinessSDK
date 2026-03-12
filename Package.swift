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
            name: "OpenBrewerySDK",
            targets: ["OpenBrewerySDK"]
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
            name: "BusinessSDKCore",
            path: "BusinessSDK/Sources/BusinessSDKCore"
        ),
        .target(
            name: "AdviceSlipSDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/AdviceSlipSDK"
        ),
        .target(
            name: "CatFactsSDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/CatFactsSDK"
        ),
        .target(
            name: "OpenBrewerySDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/OpenBrewerySDK"
        ),
        .target(
            name: "PokemonSDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/PokemonSDK"
        ),
        .target(
            name: "RickAndMortySDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/RickAndMortySDK"
        ),
        .target(
            name: "BusinessSDK",
            dependencies: ["BusinessSDKCore", "AdviceSlipSDK", "CatFactsSDK", "OpenBrewerySDK", "PokemonSDK", "RickAndMortySDK"],
            path: "BusinessSDK/Sources/BusinessSDK"
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK", "AdviceSlipSDK", "CatFactsSDK", "OpenBrewerySDK", "PokemonSDK", "RickAndMortySDK"],
            path: "BusinessSDK/Tests/BusinessSDKTests"
        )
    ]
)
