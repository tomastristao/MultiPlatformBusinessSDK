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
            name: "BusinessSDKCore",
            path: "BusinessSDK/Sources/BusinessSDKCore"
        ),
        .target(
            name: "PokemonSDK",
            dependencies: ["BusinessSDKCore"],
                path: "BusinessSDK/Sources/PokemonSDK"
        ),
        .target(
            name: "BusinessSDK",
            dependencies: ["BusinessSDKCore", "PokemonSDK"],
            path: "BusinessSDK/Sources/BusinessSDK"
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK", "PokemonSDK"],
            path: "BusinessSDK/Tests/BusinessSDKTests"
        )
    ]
)
