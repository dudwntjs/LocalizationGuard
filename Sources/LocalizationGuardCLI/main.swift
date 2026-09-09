import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
let defaultPath = FileManager.default.currentDirectoryPath
let rootPath = arguments.first ?? defaultPath
let root = URL(fileURLWithPath: rootPath)
    .standardizedFileURL

let stampPath: String? =
    arguments.indices.contains(2)
    && arguments[1] == "--stamp"
    ? arguments[2]
    : nil

let settings = Settings.load(from: root)
let scanner = ProjectScanner(
    root: root,
    settings: settings
)
let warnings = scanner.scan()

DiagnosticReporter.report(
    warnings,
    root: root
)

if let stampPath {
    let stampURL = URL(fileURLWithPath: stampPath)
    try? Data().write(to: stampURL)
}
