// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RTSComponentKit",
    platforms: [.iOS("15.0"), .tvOS("15.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RTSComponentKit",
            targets: ["RTSComponentKit"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/millicast/millicast-sdk-swift-package", from: "1.5.0"),
        .package(url: "https://github.com/DolbyIO/rts-uikit-ios", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RTSComponentKit",
            dependencies: [
                .product(name: "DolbyIOUIKit", package: "rts-uikit-ios"),
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ]),
        .testTarget(
            name: "RTSComponentKitTests",
            dependencies: [
                "RTSComponentKit",
                .product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
            ])
    ]
)
