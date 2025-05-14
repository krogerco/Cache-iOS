// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cache",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Cache",
            targets: ["Cache"])
    ],
    dependencies: [
        .package(url: "https://github.com/krogerco/Gauntlet-iOS.git", from: "2.2.0")
    ],
    targets: [
        .target(name: "Cache"),
        .testTarget(
            name: "CacheTests",
            dependencies: [
                .byName(name: "Cache"),
                .product(name: "GauntletLegacy", package: "Gauntlet-iOS")
            ]
        )
    ]
)
