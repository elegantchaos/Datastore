// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Datastore",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(name: "Datastore", targets: ["Datastore"]),
        ],
    dependencies: [
        .package(url: "git@github.com:elegantchaos/Logger.git", from: "1.3.6"),
        .package(url: "git@github.com:elegantchaos/XCTestExtensions.git", from: "1.0.4"),
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
