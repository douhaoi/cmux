// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CmuxAuthRuntime",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CmuxAuthRuntime",
            targets: ["CmuxAuthRuntime"]
        ),
    ],
    dependencies: [
        .package(path: "../CMUXAuthCore"),
        .package(path: "../CMUXMobileCore"),
    ],
    targets: [
        .target(
            name: "CmuxAuthRuntime",
            dependencies: [
                "CMUXAuthCore",
                "CMUXMobileCore",
            ],
            swiftSettings: [
                .define("CMUX_DEV_AUTH", .when(configuration: .debug)),
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "CmuxAuthRuntimeTests",
            dependencies: [
                "CmuxAuthRuntime",
            ],
            swiftSettings: [
                .define("CMUX_DEV_AUTH", .when(configuration: .debug)),
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
