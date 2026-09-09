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

        return "\(location) [LG01] \"\(value)\"가 "
            + "String Catalog에 없습니다."
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

        return "\(location) [LG02] 문자열 보간은 "
            + "String(localized:) 또는 "
            + "LocalizedStringResource로 확인하세요."
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

        return "\(location) [LG03] 존재하지 않는 "
            + "로컬라이제이션 키 \"\(key)\"입니다."
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
            ? "누락 없음"
            : "\(count)개 확인 필요"

        fputs(
            "\(root.path):1:1: warning: [LG00] "
                + "LocalizationGuard 실행 완료 — "
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
