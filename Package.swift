// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Datastore",
    platforms: [
        .macOS(.v10_14), .iOS(.v13)
    ],
    products: [
        .library(name: "Datastore", targets: ["Datastore"]),
        .library(name: "DatastoreKit", targets: ["DatastoreKit"]),
        ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.3.6"),
        .package(url: "https://github.com/elegantchaos/LayoutExtensions.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/ViewExtensions.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/CollectionExtensions.git", from: "1.0.0"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.0.7"),
        .package(url: "https://github.com/elegantchaos/Performance.git", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "Datastore",
            dependencies: ["Logger", "Performance"]),
        .target(
            name: "DatastoreKit",
            dependencies: ["CollectionExtensions", "Datastore", "LayoutExtensions", "Logger", "ViewExtensions"]),
        .testTarget(
            name: "DatastoreTests",
            dependencies: ["Datastore", "XCTestExtensions"]),
    ]
)
