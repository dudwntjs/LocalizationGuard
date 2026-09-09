import PackagePlugin

@main
struct LocalizationGuardPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {

        let tool = try context.tool(
            named: "LocalizationGuardCLI"
        )

        let stamp = context.pluginWorkDirectoryURL.appending(
            path: "LocalizationGuard.generated.swift"
        )

        return [
            .buildCommand(
                displayName: "Checking localization coverage",
                executable: tool.url,
                arguments: [
                    target.directoryURL.path,
                    "--stamp",
                    stamp.path
                ],
                inputFiles: [
                    target.directoryURL
                ],
                outputFiles: [
                    stamp
                ]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension LocalizationGuardPlugin: XcodeBuildToolPlugin {

    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {

        let tool = try context.tool(
            named: "LocalizationGuardCLI"
        )

        let stamp = context.pluginWorkDirectoryURL.appending(
            path: "LocalizationGuard.generated.swift"
        )

        return [
            .buildCommand(
                displayName: "Checking localization coverage",
                executable: tool.url,
                arguments: [
                    context.xcodeProject.directoryURL.path,
                    "--stamp",
                    stamp.path
                ],
                inputFiles: target.inputFiles.map(\.url),
                outputFiles: [
                    stamp
                ]
            )
        ]
    }
}

#endif
