// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Vigil",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Vigil", targets: ["Vigil"])
    ],
    targets: [
        .executableTarget(
            name: "Vigil",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(name: "VigilTests", dependencies: ["Vigil"])
    ]
)
