// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "apple-route",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "apple-route", targets: ["AppleRoute"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleRoute",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(name: "AppleRouteTests", dependencies: ["AppleRoute"])
    ]
)
