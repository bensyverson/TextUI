// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hello",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Hello",
            dependencies: [
                .product(name: "TextUI", package: "TextUI"),
            ],
            path: "Sources",
        ),
    ],
    swiftLanguageModes: [.v6],
)
