import Foundation

struct Settings: Decodable {
    var catalogs: [String] = []
    var excludedPaths = [
        "Tests",
        "Generated",
        "PreviewContent",
        ".build"
    ]
    var ignoredFunctions = [
        "print",
        "debugPrint",
        "assertionFailure",
        "preconditionFailure",
        "fatalError",
        "os_log"
    ]

    private enum CodingKeys: String, CodingKey {
        case catalogs
        case excludedPaths
        case ignoredFunctions
    }

    static func load(from root: URL) -> Settings {
        let configURL = root.appendingPathComponent(
            ".localizationguard.json"
        )

        guard
            let data = try? Data(contentsOf: configURL),
            let settings = try? JSONDecoder().decode(
                Settings.self,
                from: data
            )
        else {
            return Settings()
        }

        return settings
    }
}
