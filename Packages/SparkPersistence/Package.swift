// swift-tools-version: 6.0
// Package: SparkPersistence — Keychain secrets storage (SwiftData TBD).

import PackageDescription

let package = Package(
    name: "SparkPersistence",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkPersistence", targets: ["SparkPersistence"]),
    ],
    dependencies: [
        .package(path: "../SparkCore"),
    ],
    targets: [
        .target(
            name: "SparkPersistence",
            dependencies: ["SparkCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SparkPersistenceTests",
            dependencies: ["SparkPersistence"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
