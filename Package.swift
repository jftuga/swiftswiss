// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swiftswiss",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "swiftswiss",
            dependencies: ["SwiftSwissLib"]
        ),
        .target(
            name: "SwiftSwissLib",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreServices"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("CoreWLAN"),
                .linkedFramework("DiskArbitration"),
            ]
        ),
        .testTarget(
            name: "SwiftSwissTests",
            dependencies: ["SwiftSwissLib"]
        ),
    ]
)
