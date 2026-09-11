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

        return "\(location) String '\(value)' is missing from the String Catalog."
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

        return "\(location) Verify string interpolation uses "
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

        return "\(location) Localization key '\(key)' was not found in the String Catalog."
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
            "\(root.path):1:1: note: LocalizationGuard: "
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
