// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mqtt-nio-chat",
    platforms: [.macOS(.v10_14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(name: "MQTTNIOChat", targets: ["mqtt-nio-chat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adam-fowler/mqtt-nio.git", .branch("main")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "mqtt-nio-chat", dependencies: [
            .product(name: "MQTTNIO", package: "mqtt-nio"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ])
    ]
)
