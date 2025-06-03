// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fmb-cli",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "fmb", targets: [ "fmb-cli" ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.5.1"),
        .package(url: "https://github.com/httpswift/swifter.git", exact: "1.5.0"),
        .package(url: "https://github.com/tuist/Noora", exact: "0.38.0"),
        .package(url: "https://github.com/supabase/supabase-swift.git", exact: "2.29.1"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", exact: "2.8.7"),
        .package(url: "https://github.com/FlineDev/ErrorKit.git", exact: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "fmb-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Swifter", package: "swifter"),
                .product(name: "Noora", package: "Noora"),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "ErrorKit", package: "ErrorKit")
            ]
        )
    ]
)
