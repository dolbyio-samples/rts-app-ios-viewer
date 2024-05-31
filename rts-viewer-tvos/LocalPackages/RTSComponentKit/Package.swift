// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RTSComponentKit",
    defaultLocalization: "en",
    platforms: [.iOS("15.0"), .tvOS("15.0")],
    products: [
        .library(
            name: "RTSComponentKit",
            targets: ["RTSComponentKit"]
        ),
        .library(
            name: "DolbyIOUIKit",
            targets: ["DolbyIOUIKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", exact: "2.0.0-beta.2")
    ],
    targets: [
        .target(
            name: "DolbyIOUIKit",
            dependencies: [],
            path: "Sources/DolbyIOUIKit",
            resources: [.process("Resources")]
        ),
        .target(
            name: "RTSComponentKit",
            dependencies: [
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ]
        ),
        .testTarget(
            name: "RTSComponentKitTests",
            dependencies: [
                "RTSComponentKit",
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ]
        )
    ]
)
