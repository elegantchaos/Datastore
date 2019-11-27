// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Datastore",
    platforms: [
        .macOS(.v10_14), .iOS(.v13)
    ],
    products: [
        .library(name: "Datastore", targets: ["Datastore"]),
        ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.3.6"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.0.5"),
    ],
    targets: [
        .target(
            name: "Datastore",
            dependencies: ["Logger"]),
        .testTarget(
            name: "DatastoreTests",
            dependencies: ["Datastore", "XCTestExtensions"]),
    ]
)
