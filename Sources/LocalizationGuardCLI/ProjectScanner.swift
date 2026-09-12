import Foundation

struct ProjectScanner {
    private let root: URL
    private let settings: Settings

    private let literalPatterns = [
        #"Text\s*\(\s*verbatim\s*:\s*\"((?:\\.|[^\"\\])*)\""#,
        #"(?:\.text\s*=|setTitle\s*\()\s*\"((?:\\.|[^\"\\])*)\""#,
        #"(?:Text|Button|Label|navigationTitle|accessibilityLabel)\s*\(\s*\"((?:\\.|[^\"\\])*)\""#
    ]
    private let localizedKeyPattern =
        #"(?:String\s*\(\s*localized\s*:|LocalizedStringResource\s*\()\s*\"((?:\\.|[^\"\\])*)\""#
    private let anyStringLiteralPattern =
        #"\"((?:\\.|[^\"\\])*)\""#
    private let sourceLanguagePatterns = [
        "ko": #"[\u{AC00}-\u{D7A3}]"#,
        "ja": #"[\u{3040}-\u{30FF}\u{3400}-\u{4DBF}\u{4E00}-\u{9FFF}]"#
    ]

    init(
        root: URL,
        settings: Settings
    ) {
        self.root = root
        self.settings = settings
    }

    func scan() -> [String] {
        let catalogs = catalogURLs()
        let keys = catalogKeys(in: catalogs)
        var warnings = catalogs.flatMap {
            CatalogScanner(requiredLanguages: settings.requiredLanguages).scan(file: $0)
        }

        for file in projectFiles(extension: "swift") {
            warnings += scan(file: file, keys: keys)
        }

        return warnings
    }

    private func projectFiles(
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

            let relativePath = url.path
                .replacingOccurrences(
                    of: root.path + "/",
                    with: ""
                )
            let pathComponents = relativePath.split(
                separator: "/"
            )
            let isExcluded = settings.excludedPaths
                .contains {
                    pathComponents.contains(Substring($0))
                }

            return isExcluded ? nil : url
        }
    }

    private func catalogURLs() -> [URL] {
        if settings.catalogs.isEmpty {
            return projectFiles(extension: "xcstrings")
        }
        return settings.catalogs.map { root.appendingPathComponent($0) }
    }

    private func catalogKeys(in catalogURLs: [URL]) -> Set<String> {
        return catalogURLs.reduce(into: Set<String>()) {
            keys,
            catalogURL in
            guard
                let data = try? Data(contentsOf: catalogURL),
                let json = try? JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any]
            else {
                return
            }

            let strings = json["strings"]
                as? [String: Any] ?? [:]
            keys.formUnion(strings.keys)
        }
    }

    private func scan(
        file: URL,
        keys: Set<String>
    ) -> [String] {
        guard let source = try? String(
            contentsOf: file,
            encoding: .utf8
        ) else {
            return []
        }

        let lines = source.components(
            separatedBy: .newlines
        )
        var state = ScanState()
        var warnings: [String] = []

        for (index, line) in lines.enumerated() {
            if shouldSkip(
                line: line,
                index: index,
                lines: lines,
                state: &state
            ) {
                continue
            }

            warnings += literalWarnings(
                line: line,
                lineNumber: index + 1,
                file: file,
                keys: keys
            )
        }

        return warnings
    }

    private func shouldSkip(
        line: String,
        index: Int,
        lines: [String],
        state: inout ScanState
    ) -> Bool {
        if line.contains("#Preview") {
            state.isInsidePreview = true
        }

        if state.isInsidePreview {
            state.previewBraceDepth += line.filter {
                $0 == "{"
            }.count
            state.previewBraceDepth -= line.filter {
                $0 == "}"
            }.count

            if state.previewBraceDepth <= 0,
               line.contains("}") {
                state.isInsidePreview = false
                state.previewBraceDepth = 0
            }

            return true
        }

        if state.ignoredCallDepth > 0 {
            state.ignoredCallDepth += line.filter {
                $0 == "("
            }.count
            state.ignoredCallDepth -= line.filter {
                $0 == ")"
            }.count
            return true
        }

        if line.contains(
            "localization-guard:disable-line"
        ) {
            return true
        }

        if index > 0,
           lines[index - 1].contains(
               "localization-guard:disable-next-line"
           ) {
            return true
        }

        if isIgnoredDiagnosticLine(line) {
            let openingCount = line.filter {
                $0 == "("
            }.count
            let closingCount = line.filter {
                $0 == ")"
            }.count
            state.ignoredCallDepth = max(
                openingCount - closingCount,
                0
            )
            return true
        }

        return false
    }

    private func literalWarnings(
        line: String,
        lineNumber: Int,
        file: URL,
        keys: Set<String>
    ) -> [String] {
        var warnings: [String] = []

        for pattern in literalPatterns {
            for match in matches(pattern, in: line) {
                let value = decoded(match.value)

                if match.value.contains(#"\("#) {
                    warnings.append(
                        DiagnosticReporter.interpolation(
                            file: file,
                            line: lineNumber,
                            column: match.column
                        )
                    )
                } else if !value.isEmpty,
                          !keys.contains(value) {
                    warnings.append(
                        DiagnosticReporter.missingKey(
                            value: value,
                            file: file,
                            line: lineNumber,
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
                    DiagnosticReporter.unknownKey(
                        key: key,
                        file: file,
                        line: lineNumber,
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

            guard containsSourceLanguage(value) else {
                continue
            }

            if match.value.contains(#"\("#) {
                warnings.append(
                    DiagnosticReporter.interpolation(
                        file: file,
                        line: lineNumber,
                        column: match.column
                    )
                )
            } else if !keys.contains(value) {
                warnings.append(
                    DiagnosticReporter.missingKey(
                        value: value,
                        file: file,
                        line: lineNumber,
                        column: match.column
                    )
                )
            }
        }

        return warnings
    }

    private func matches(
        _ pattern: String,
        in line: String
    ) -> [(value: String, column: Int)] {
        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return []
        }

        let lineRange = NSRange(
            line.startIndex...,
            in: line
        )

        return regex.matches(
            in: line,
            range: lineRange
        ).compactMap { match in
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

    private func decoded(_ value: String) -> String {
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

    private func containsSourceLanguage(
        _ value: String
    ) -> Bool {
        settings.sourceLanguages.contains { language in
            guard let pattern = sourceLanguagePatterns[language] else {
                return false
            }

            return value.range(
                of: pattern,
                options: .regularExpression
            ) != nil
        }
    }

    private func isIgnoredDiagnosticLine(
        _ line: String
    ) -> Bool {
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
}

private struct ScanState {
    var previewBraceDepth = 0
    var isInsidePreview = false
    var ignoredCallDepth = 0
}
