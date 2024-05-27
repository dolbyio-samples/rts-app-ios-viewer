// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DolbyIORTSUIKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "DolbyIOUIKit",
            targets: ["DolbyIOUIKit"]),
        .library(
            name: "DolbyIORTSCore",
            targets: ["DolbyIORTSCore"]),
        .library(
            name: "DolbyIORTSUIKit",
            targets: ["DolbyIORTSUIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", exact: "1.8.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DolbyIOUIKit",
            dependencies: [],
            path: "Sources/DolbyIOUIKit",
            resources: [.process("Resources")]
            ),
        .target(
            name: "DolbyIORTSCore",
            dependencies: [
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ],
            path: "Sources/DolbyIORTSCore"
        ),
        .target(
            name: "DolbyIORTSUIKit",
            dependencies: [
                "DolbyIOUIKit",
                "DolbyIORTSCore"
            ],
            path: "Sources/DolbyIORTSUIKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DolbyIOUIKitTests",
            dependencies: ["DolbyIOUIKit"]),
        .testTarget(
            name: "DolbyIORTSCoreTests",
            dependencies: ["DolbyIORTSCore"]),
        .testTarget(
            name: "DolbyIORTSUIKitTests",
            dependencies: ["DolbyIORTSUIKit", "DolbyIORTSCore"])
    ]
)
