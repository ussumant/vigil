// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CaffeinateBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CaffeinateBar", targets: ["CaffeinateBar"])
    ],
    targets: [
        .executableTarget(
            name: "CaffeinateBar",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(name: "CaffeinateBarTests", dependencies: ["CaffeinateBar"])
    ]
)
