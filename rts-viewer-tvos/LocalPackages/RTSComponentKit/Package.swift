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
        // .package(url: "https://github.com/millicast/millicast-sdk-swift-package", exact: "1.8.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(name: "MillicastSDK", path: "../MillicastSDK.xcframework"),
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
                .byName(name: "MillicastSDK")
            ]
        )
    ]
)
