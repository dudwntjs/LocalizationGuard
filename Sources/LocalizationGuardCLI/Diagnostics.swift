import Foundation

enum DiagnosticReporter {
    static func missingKey(
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

        return "\(location) Missing translation: String '\(value)' is missing from the String Catalog."
    }

    static func interpolation(
        file: URL,
        line: Int,
        column: Int
    ) -> String {
        let location = location(
            file: file,
            line: line,
            column: column
        )

        return "\(location) String interpolation: Verify string interpolation uses "
            + "String(localized:) or LocalizedStringResource."
    }

    static func unknownKey(
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

        return "\(location) Unknown localization key: Key '\(key)' was not found in the String Catalog."
    }

    static func missingLanguage(key: String, language: String, file: URL) -> String {
        let location = location(file: file, line: 1, column: 1)
        return "\(location) Missing language: Translation for key '\(key)' is missing or empty for language '\(language)'."
    }

    static func report(
        _ warnings: [String],
        root: URL
    ) {
        let uniqueWarnings = Set(warnings).sorted()

        for warning in uniqueWarnings {
            fputs(warning + "\n", stderr)
        }

        let count = uniqueWarnings.count
        let summary = count == 0
            ? "No localization issues found."
            : "Found \(count) localization \(count == 1 ? "issue" : "issues") to review."

        fputs(
            "\(root.path):1:1: note: Localization summary: "
                + "\(summary)\n",
            stderr
        )
    }

    private static func location(
        file: URL,
        line: Int,
        column: Int
    ) -> String {
        "\(file.path):\(line):\(column): warning:"
    }
}
