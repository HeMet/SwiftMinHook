// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-minhook",
    products: [
        .library(
            name: "SwiftMinHook",
            targets: ["SwiftMinHook"]),
    ],
    targets: [
        .target(
            name: "SwiftMinHook",
            dependencies: ["MinHook"]),
        .target(
            name: "MinHook",
            dependencies: []
            // cSettings: [.unsafeFlags(["-fapinotes-modules"])]
            ),
        .testTarget(
            name: "MinHookTests",
            dependencies: ["MinHook"]),
        .testTarget(
            name: "SwiftMinHookTests",
            dependencies: ["SwiftMinHook"])
    ]
)
