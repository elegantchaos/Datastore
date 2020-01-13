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
        .package(url: "https://github.com/elegantchaos/Layout.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.0.5"),
    ],
    targets: [
        .target(
            name: "Datastore",
            dependencies: ["Logger"]),
        .target(
            name: "DatastoreKit",
            dependencies: ["Datastore", "Layout", "Logger"]),
        .testTarget(
            name: "DatastoreTests",
            dependencies: ["Datastore", "XCTestExtensions"]),
    ]
)
