// swift-tools-version: 5.9
import PackageDescription

// Do not attach .unsafeFlags to library targets consumed by the app;
// Xcode then reports Missing package product for those products.
// App target uses SWIFT_STRICT_CONCURRENCY=complete instead.

let package = Package(
    name: "CoordinateKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoordinateDomain", targets: ["CoordinateDomain"]),
        .library(name: "CoordinateModels", targets: ["CoordinateModels"]),
        .library(name: "CoordinateData", targets: ["CoordinateData"]),
        .library(name: "CoordinateNetworking", targets: ["CoordinateNetworking"]),
        .library(name: "CoordinateFeatureFlags", targets: ["CoordinateFeatureFlags"]),
    ],
    targets: [
        .target(name: "CoordinateModels"),
        .target(
            name: "CoordinateDomain",
            dependencies: ["CoordinateModels"]
        ),
        .target(
            name: "CoordinateData",
            dependencies: ["CoordinateDomain"]
        ),
        .target(
            name: "CoordinateNetworking",
            linkerSettings: [
                .linkedFramework("Network"),
            ]
        ),
        .target(name: "CoordinateFeatureFlags"),
        .testTarget(
            name: "CoordinateDomainTests",
            dependencies: ["CoordinateDomain"]
        ),
        .testTarget(
            name: "CoordinateNetworkingTests",
            dependencies: ["CoordinateNetworking"]
        ),
    ]
)
