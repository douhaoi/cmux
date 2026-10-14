// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CmuxIrxTransport",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CmuxIrxTransport",
            targets: ["CmuxIrxTransport"]
        ),
    ],
    dependencies: [
        .package(path: "../CMUXMobileCore"),
        // Grant claims/verifier and terminal-envelope codecs are consumed as
        // stable data contracts; none of the legacy runtime machinery is used.
        .package(path: "../CmuxIrohTransport"),
    ],
    targets: [
        .target(
            name: "CmuxIrxTransport",
            dependencies: [
                "CMUXMobileCore",
                "CmuxIrohTransport",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ],
            linkerSettings: [
                .linkedFramework("Security"),
            ]
        ),
        .testTarget(
            name: "CmuxIrxTransportTests",
            dependencies: [
                "CmuxIrxTransport",
                "CMUXMobileCore",
                "CmuxIrohTransport",
            ],
            resources: [
                .copy("V2/Fixtures"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
