// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RTSCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "RTSCore",
            targets: ["RTSCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", exact: "2.0.0-beta.2")
    ],
    targets: [
        .target(
            name: "RTSCore",
            dependencies: [
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ],
            path: "Sources/RTSCore"
        ),
        .testTarget(
            name: "RTSCoreTests",
            dependencies: ["RTSCore"])
    ]
)
