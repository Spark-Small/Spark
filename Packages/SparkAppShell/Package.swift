// swift-tools-version: 6.0
// Module: SparkAppShell — App root navigation, tabs, deep links.

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
        .package(path: "../SparkDesignSystem"),
        .package(path: "../SparkMessages"),
        .package(path: "../SparkActivity"),
        .package(path: "../SparkSearch"),
        .package(path: "../SparkLikes"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkNotifications"),
        .package(path: "../SparkPersistence"),
        .package(path: "../SparkPayments"),
        .package(path: "../SparkProfile"),
        .package(path: "../SparkTrust")
    ],
    targets: [
        .target(
            name: "SparkAppShell",
            dependencies: [
                "SparkAuth",
                "SparkCommunity",
                "SparkDesignSystem",
                "SparkMessages",
                "SparkActivity",
                "SparkLikes",
                "SparkSearch",
                "SparkNetworking",
                "SparkNotifications",
                "SparkPersistence",
                "SparkPayments",
                "SparkProfile",
                "SparkTrust"
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
