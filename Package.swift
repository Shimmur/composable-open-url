// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "composable-open-url",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "ComposableOpenURL",
            targets: ["ComposableOpenURL"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
//            from: "0.34.0",
            .branch("proto-2")
        ),
    ],
    targets: [
        .target(
            name: "ComposableOpenURL",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]),
        .testTarget(
            name: "ComposableOpenURLTests",
            dependencies: ["ComposableOpenURL"]),
    ]
)
