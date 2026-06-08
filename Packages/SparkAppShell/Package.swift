// swift-tools-version: 6.0
// Package: SparkAppShell — App root navigation, tabs, deep links.

import PackageDescription

let package = Package(
    name: "SparkAppShell",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkAppShell", targets: ["SparkAppShell"])
    ],
    dependencies: [
        .package(path: "../SparkAuth"),
        .package(path: "../SparkCommunity"),
        .package(path: "../SparkMessages"),
        .package(path: "../SparkActivity"),
        .package(path: "../SparkSearch"),
        .package(path: "../SparkLikes"),
        .package(path: "../SparkProfile"),
        .package(path: "../SparkPersistence"),
        .package(path: "../SparkPayments")
    ],
    targets: [
        .target(
            name: "SparkAppShell",
            dependencies: [
                "SparkAuth",
                "SparkCommunity",
                "SparkMessages",
                "SparkActivity",
                "SparkLikes",
                "SparkProfile",
                "SparkSearch",
                "SparkPersistence",
                "SparkPayments"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkAppShellTests",
            dependencies: ["SparkAppShell", "SparkPayments"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
