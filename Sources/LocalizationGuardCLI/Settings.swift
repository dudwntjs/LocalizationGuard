import Foundation

struct Settings: Decodable {
    var catalogs: [String] = []
    var requiredLanguages: [String] = []
    var sourceLanguages = ["ko"]
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
        case requiredLanguages
        case sourceLanguages
        case excludedPaths
        case ignoredFunctions
    }

    init() {}

    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        catalogs = try values.decodeIfPresent([String].self, forKey: .catalogs) ?? catalogs
        requiredLanguages = try values.decodeIfPresent([String].self, forKey: .requiredLanguages) ?? requiredLanguages
        sourceLanguages = try values.decodeIfPresent([String].self, forKey: .sourceLanguages) ?? sourceLanguages
        excludedPaths = try values.decodeIfPresent([String].self, forKey: .excludedPaths) ?? excludedPaths
        ignoredFunctions = try values.decodeIfPresent([String].self, forKey: .ignoredFunctions) ?? ignoredFunctions
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
