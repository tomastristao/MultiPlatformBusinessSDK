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
    ],
    targets: [
        .target(
            name: "BusinessSDKCore"
        ),
        .target(
            name: "PokemonSDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .target(
            name: "BusinessSDK",
            dependencies: ["BusinessSDKCore", "PokemonSDK"]
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK", "PokemonSDK"]
        )
    ]
)
