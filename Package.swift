// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hello",
    products: [
        .executable(name: "Hello", targets: ["Hello"])
    ],
    targets: [
        .executableTarget(
            name: "Hello",
            path: "Sources"
        )
    ]
)
