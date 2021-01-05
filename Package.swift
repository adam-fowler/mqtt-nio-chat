// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mqtt-nio-chat",
    platforms: [.macOS(.v10_14)],
    products: [
        .executable(name: "MQTTNIOChat", targets: ["mqtt-nio-chat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adam-fowler/mqtt-nio.git", .branch("main")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.0"),
    ],
    targets: [
        .target(name: "mqtt-nio-chat", dependencies: [
            .product(name: "MQTTNIO", package: "mqtt-nio"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ])
    ]
)
