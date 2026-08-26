// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "qualtive",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0"),
    ],
    products: [
        .library(name: "qualtive", targets: ["qualtive"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "qualtive",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "QualtiveNative",
            ]
        ),
        .target(
            name: "QualtiveNative",
            path: "qualtive-client-swift/Sources/Qualtive",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
    ]
)
