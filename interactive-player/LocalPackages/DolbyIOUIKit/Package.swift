// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DolbyIOUIKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "DolbyIOUIKit",
            targets: ["DolbyIOUIKit"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DolbyIOUIKit",
            dependencies: [],
            path: "Sources/DolbyIOUIKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DolbyIOUIKitTests",
            dependencies: ["DolbyIOUIKit"]
        )
    ]
)
