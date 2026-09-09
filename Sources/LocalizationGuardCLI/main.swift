import Foundation

// MARK: - Configuration

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
}

// MARK: - Command-Line Arguments

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

// MARK: - Configuration Loading

let configURL = root.appendingPathComponent(
    ".localizationguard.json"
)
let settings = (try? Data(contentsOf: configURL))
    .flatMap { data in
        try? JSONDecoder().decode(
            Settings.self,
            from: data
        )
    } ?? Settings()

// MARK: - File Discovery

func projectFiles(
    extension extensionName: String
) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil
    ) else {
        return []
    }

    return enumerator.compactMap { item in
        guard
            let url = item as? URL,
            url.pathExtension == extensionName
        else {
            return nil
        }

        let relativePath = url.path.replacingOccurrences(
            of: root.path + "/",
            with: ""
        )
        let pathComponents = relativePath.split(
            separator: "/"
        )
        let isExcluded = settings.excludedPaths.contains {
            pathComponents.contains(Substring($0))
        }

        return isExcluded ? nil : url
    }
}

// MARK: - String Catalog

let catalogURLs: [URL]

if settings.catalogs.isEmpty {
    catalogURLs = projectFiles(extension: "xcstrings")
} else {
    catalogURLs = settings.catalogs.map {
        root.appendingPathComponent($0)
    }
}

var keys = Set<String>()
var warnings: [String] = []

for catalogURL in catalogURLs {
    guard
        let data = try? Data(contentsOf: catalogURL),
        let json = try? JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]
    else {
        continue
    }

    let strings = json["strings"] as? [String: Any]
        ?? [:]
    keys.formUnion(strings.keys)
}

// MARK: - Pattern Definitions

let literalPatterns = [
    #"Text\s*\(\s*verbatim\s*:\s*\"((?:\\.|[^\"\\])*)\""#,
    #"(?:\.text\s*=|setTitle\s*\()\s*\"((?:\\.|[^\"\\])*)\""#,
    #"(?:Text|Button|Label|navigationTitle|accessibilityLabel)\s*\(\s*\"((?:\\.|[^\"\\])*)\""#
]
let localizedKeyPattern =
    #"(?:String\s*\(\s*localized\s*:|LocalizedStringResource\s*\()\s*\"((?:\\.|[^\"\\])*)\""#
let anyStringLiteralPattern =
    #"\"((?:\\.|[^\"\\])*)\""#
let koreanPattern = #"[\u{AC00}-\u{D7A3}]"#

// MARK: - Pattern Matching

func matches(
    _ pattern: String,
    in line: String
) -> [(value: String, column: Int)] {
    guard let regex = try? NSRegularExpression(
        pattern: pattern
    ) else {
        return []
    }

    let lineRange = NSRange(line.startIndex..., in: line)
    return regex.matches(in: line, range: lineRange)
        .compactMap { match in
            guard
                match.numberOfRanges > 1,
                let range = Range(
                    match.range(at: 1),
                    in: line
                )
            else {
                return nil
            }

            return (
                value: String(line[range]),
                column: match.range.location + 1
            )
        }
}

func decoded(_ value: String) -> String {
    let escapedValue = value.replacingOccurrences(
        of: "\"",
        with: "\\\""
    )
    let json = "\"\(escapedValue)\""

    return (try? JSONDecoder().decode(
        String.self,
        from: Data(json.utf8)
    )) ?? value
}

func containsKorean(_ value: String) -> Bool {
    value.range(
        of: koreanPattern,
        options: .regularExpression
    ) != nil
}

func isIgnoredDiagnosticLine(_ line: String) -> Bool {
    settings.ignoredFunctions.contains { function in
        let escapedFunction =
            NSRegularExpression.escapedPattern(
                for: function
            )
        let pattern =
            #"\b"# + escapedFunction + #"\s*\("#

        return line.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}

// MARK: - Diagnostics

func location(
    file: URL,
    line: Int,
    column: Int
) -> String {
    "\(file.path):\(line):\(column): warning:"
}

func missingKeyWarning(
    value: String,
    file: URL,
    line: Int,
    column: Int
) -> String {
    let location = location(
        file: file,
        line: line,
        column: column
    )
    return "\(location) [LG01] \"\(value)\"가 "
        + "String Catalog에 없습니다."
}

func interpolationWarning(
    file: URL,
    line: Int,
    column: Int
) -> String {
    let location = location(
        file: file,
        line: line,
        column: column
    )
    return "\(location) [LG02] 문자열 보간은 "
        + "String(localized:) 또는 "
        + "LocalizedStringResource로 확인하세요."
}

func unknownKeyWarning(
    key: String,
    file: URL,
    line: Int,
    column: Int
) -> String {
    let location = location(
        file: file,
        line: line,
        column: column
    )
    return "\(location) [LG03] 존재하지 않는 "
        + "로컬라이제이션 키 \"\(key)\"입니다."
}

// MARK: - Source Scanning

for file in projectFiles(extension: "swift") {
    guard let source = try? String(
        contentsOf: file,
        encoding: .utf8
    ) else {
        continue
    }

    let lines = source.components(separatedBy: .newlines)
    var previewBraceDepth = 0
    var isInsidePreview = false
    var ignoredCallParenthesisDepth = 0

    for (index, line) in lines.enumerated() {
        if line.contains("#Preview") {
            isInsidePreview = true
        }

        if isInsidePreview {
            previewBraceDepth += line.filter {
                $0 == "{"
            }.count
            previewBraceDepth -= line.filter {
                $0 == "}"
            }.count

            if previewBraceDepth <= 0,
               line.contains("}") {
                isInsidePreview = false
                previewBraceDepth = 0
            }

            continue
        }

        if ignoredCallParenthesisDepth > 0 {
            ignoredCallParenthesisDepth += line.filter {
                $0 == "("
            }.count
            ignoredCallParenthesisDepth -= line.filter {
                $0 == ")"
            }.count
            continue
        }

        if line.contains(
            "localization-guard:disable-line"
        ) {
            continue
        }

        if index > 0,
           lines[index - 1].contains(
               "localization-guard:disable-next-line"
           ) {
            continue
        }

        if isIgnoredDiagnosticLine(line) {
            let openingCount = line.filter {
                $0 == "("
            }.count
            let closingCount = line.filter {
                $0 == ")"
            }.count

            ignoredCallParenthesisDepth = max(
                openingCount - closingCount,
                0
            )
            continue
        }

        for pattern in literalPatterns {
            for match in matches(pattern, in: line) {
                let value = decoded(match.value)

                if match.value.contains(#"\("#) {
                    warnings.append(
                        interpolationWarning(
                            file: file,
                            line: index + 1,
                            column: match.column
                        )
                    )
                } else if !value.isEmpty,
                          !keys.contains(value) {
                    warnings.append(
                        missingKeyWarning(
                            value: value,
                            file: file,
                            line: index + 1,
                            column: match.column
                        )
                    )
                }
            }
        }

        for match in matches(localizedKeyPattern, in: line) {
            let key = decoded(match.value)

            if !keys.contains(key) {
                warnings.append(
                    unknownKeyWarning(
                        key: key,
                        file: file,
                        line: index + 1,
                        column: match.column
                    )
                )
            }
        }

        for match in matches(
            anyStringLiteralPattern,
            in: line
        ) {
            let value = decoded(match.value)

            guard containsKorean(value) else {
                continue
            }

            if match.value.contains(#"\("#) {
                warnings.append(
                    interpolationWarning(
                        file: file,
                        line: index + 1,
                        column: match.column
                    )
                )
            } else if !keys.contains(value) {
                warnings.append(
                    missingKeyWarning(
                        value: value,
                        file: file,
                        line: index + 1,
                        column: match.column
                    )
                )
            }
        }
    }
}

// MARK: - Results

let uniqueWarnings = Set(warnings).sorted()

for warning in uniqueWarnings {
    fputs(warning + "\n", stderr)
}

let count = uniqueWarnings.count
let summary = count == 0
    ? "누락 없음"
    : "\(count)개 확인 필요"

fputs(
    "\(root.path):1:1: warning: [LG00] "
        + "LocalizationGuard 실행 완료 — \(summary)\n",
    stderr
)

// MARK: - Build Completion

if let stampPath {
    let stampURL = URL(fileURLWithPath: stampPath)
    try? Data().write(to: stampURL)
}
