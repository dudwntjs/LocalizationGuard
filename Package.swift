// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "LocalizationGuard",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "LocalizationGuardCLI",
            targets: ["LocalizationGuardCLI"]
        ),
        .plugin(
            name: "LocalizationGuardPlugin",
            targets: ["LocalizationGuardPlugin"]
        )
    ],
    targets: [
        .executableTarget(name: "LocalizationGuardCLI"),
        .plugin(
            name: "LocalizationGuardPlugin",
            capability: .buildTool(),
            dependencies: ["LocalizationGuardCLI"]
        ),
    ]
)
