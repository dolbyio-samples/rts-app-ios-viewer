// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DolbyIORTSUIKit",
    platforms: [.iOS("15.0"), .tvOS("15.0")],
    products: [
        .library(
            name: "DolbyIORTSUIKit",
            targets: ["DolbyIORTSUIKit"]),
        .library(
            name: "DolbyIORTSCore",
            targets: ["DolbyIORTSCore"])
    ],
    dependencies: [
        .package(name: "DolbyIOUIKit", path: "../DolbyIOUIKit"),
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "DolbyIORTSUIKit",
            dependencies: [
                .product(name: "DolbyIOUIKit", package: "DolbyIOUIKit"),
                "DolbyIORTSCore"
            ],
            path: "Sources/DolbyIORTSUIKit"
        ),
        .target(
            name: "DolbyIORTSCore",
            dependencies: [
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ],
            path: "Sources/DolbyIORTSCore"
        ),
        .testTarget(
            name: "DolbyIORTSUIKitTests",
            dependencies: ["DolbyIORTSUIKit", "DolbyIORTSCore"]
        )
    ]
)
