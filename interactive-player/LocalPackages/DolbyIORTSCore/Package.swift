// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DolbyIORTSCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "DolbyIORTSCore",
            targets: ["DolbyIORTSCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", exact: "2.0.0-beta.2")
    ],
    targets: [
        .target(
            name: "DolbyIORTSCore",
            dependencies: [
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ],
            path: "Sources/DolbyIORTSCore"
        ),
        .testTarget(
            name: "DolbyIORTSCoreTests",
            dependencies: ["DolbyIORTSCore"])
    ]
)
