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
    ],
    targets: [
        .binaryTarget(name: "MillicastSDK", path: "millicast-native-sdk-2.0.0-XCFramework/MillicastSDK.xcframework"),
        .target(
            name: "DolbyIOUIKit",
            dependencies: [],
            path: "Sources/DolbyIOUIKit",
            resources: [.process("Resources")]
        ),
        .target(
            name: "RTSComponentKit",
            dependencies: [
                .byName(name: "DolbyIOUIKit"),
                .byName(name: "MillicastSDK")
            ]
        ),
        .testTarget(
            name: "RTSComponentKitTests",
            dependencies: [
                "RTSComponentKit",
                "MillicastSDK"
            ]
        )
    ]
)
