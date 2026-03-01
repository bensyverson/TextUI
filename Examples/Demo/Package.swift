// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Demo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Demo",
            dependencies: [
                .product(name: "TextUI", package: "TextUI"),
            ],
            path: "Sources",
        ),
    ],
    swiftLanguageModes: [.v6],
)
