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
    ],
    targets: [
        .target(
            name: "BusinessSDKCore"
        ),

        .target(
            name: "BusinessSDK",
            dependencies: ["BusinessSDKCore"]
        ),
        .testTarget(
            name: "BusinessSDKTests",
            dependencies: ["BusinessSDK"]
        )
    ]
)
