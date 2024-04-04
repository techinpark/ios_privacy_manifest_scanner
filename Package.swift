// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "privacy_scanner",
    products: [
        .executable(name: "privacy_scanner", targets: ["privacy_scanner"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "privacy_scanner",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"
        ),
    ]
)
