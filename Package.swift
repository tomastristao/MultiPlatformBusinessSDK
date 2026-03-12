// swift-tools-version: 6.2

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
            dependencies: ["BusinessSDKCore", "PokemonSDK", "RickAndMortySDK"],
            path: "BusinessSDK/Sources/BusinessSDK"
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK", "PokemonSDK", "RickAndMortySDK"],
            path: "BusinessSDK/Tests/BusinessSDKTests"
        )
    ]
)
