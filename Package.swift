// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Datastore",
    platforms: [
        .macOS(.v10_15), .iOS(.v12)
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
