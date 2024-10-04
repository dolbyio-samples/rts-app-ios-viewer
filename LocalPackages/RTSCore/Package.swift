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
        // Uncomment the below to consume Production, Alpha or Beta versions of SDK
        //.package(url: "https://github.com/millicast/millicast-sdk-swift-package", .upToNextMajor(from: Version(2, 0, 0, prereleaseIdentifiers: ["beta"])))
    ],
    targets: [
        // Comment the below `binaryTarget` when using a Prod release of the SDK
        .binaryTarget(
            name: "MillicastSDK",
            url: "https://jfrog-sfo.dolby.net:443/artifactory/dolbyio-rts-generic-fed/GitHubArtefacts/CoSMoSoftware/csmMillicastNativeSdk/staging/branch_dev/id-3706_sha-e878dc80/ios/millicast-native-sdk-2.1.0-XCFramework.zip",
            checksum: "85347684dd2dd97e5d93f91a615e5952764aa126bfd782ff45ff39b12ebc09c4"
        ),
        .target(
            name: "RTSCore",
            dependencies: [
                //.product(name: "MillicastSDK", package: "millicast-sdk-swift-package")
                .byName(name: "MillicastSDK")
            ],
            path: "Sources/RTSCore"
        ),
        .testTarget(
            name: "RTSCoreTests",
            dependencies: ["RTSCore"]
        )
    ]
)
