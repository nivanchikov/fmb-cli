// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fmb-cli",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "fmb", targets: ["fmb-cli"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.5.1"),
        .package(url: "https://github.com/httpswift/swifter.git", exact: "1.5.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", exact: "1.4.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", exact: "4.2.2"),
        .package(url: "https://github.com/tuist/Noora", exact: "0.38.0"),
        .package(url: "https://github.com/eastriverlee/LLM.swift.git", exact: "1.7.2"),
    ],
    targets: [
        .executableTarget(
            name: "fmb-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Swifter", package: "swifter"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Noora", package: "Noora"),
                .product(name: "LLM", package: "LLM.swift"),
            ]
        )
    ]
)
