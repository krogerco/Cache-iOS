// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cache",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Cache",
            targets: ["Cache"])
    ],
    dependencies: [
        .package(url: "https://github.com/krogerco/Gauntlet-iOS.git", from: Version(1, 0, 0))
    ],
    targets: [
        .target(name: "Cache"),
        .testTarget(
            name: "CacheTests",
            dependencies: [
                .byName(name: "Cache"),
                .product(name: "Gauntlet", package: "Gauntlet-iOS")
            ]
        )
    ]
)
