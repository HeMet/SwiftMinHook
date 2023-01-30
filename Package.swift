// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-minhook",
    products: [
        .library(
            name: "SwiftMinHook",
            targets: ["MinHook"]),
    ],
    targets: [
        .target(
            name: "MinHook",
            dependencies: []),
        .testTarget(
            name: "MinHookTests",
            dependencies: ["MinHook"]),
    ]
)
