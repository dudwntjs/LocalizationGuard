import Foundation

struct CatalogScanner {
    let requiredLanguages: [String]

    func scan(file: URL) -> [String] {
        guard
            let data = try? Data(contentsOf: file),
            let catalog = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let sourceLanguage = catalog["sourceLanguage"] as? String,
            let strings = catalog["strings"] as? [String: Any]
        else {
            return []
        }

        var languages = Set(requiredLanguages)
        if languages.isEmpty {
            for case let entry as [String: Any] in strings.values {
                guard entry["shouldTranslate"] as? Bool != false,
                      entry["extractionState"] as? String != "stale" else { continue }
                let localizations = entry["localizations"] as? [String: Any] ?? [:]
                languages.formUnion(localizations.keys)
            }
        }
        languages.remove(sourceLanguage)

        var warnings: [String] = []
        for key in strings.keys.sorted() where !key.isEmpty {
            guard let entry = strings[key] as? [String: Any],
                  entry["shouldTranslate"] as? Bool != false,
                  entry["extractionState"] as? String != "stale" else { continue }
            let localizations = entry["localizations"] as? [String: Any] ?? [:]
            for language in languages.sorted() {
                guard let translation = localizations[language] as? [String: Any],
                      hasValues(translation) else {
                    warnings.append(DiagnosticReporter.missingLanguage(
                        key: key, language: language, file: file
                    ))
                    continue
                }
            }
        }
        return warnings
    }

    private func hasValues(_ translation: [String: Any]) -> Bool {
        var hasContent = false
        if let unit = translation["stringUnit"] as? [String: Any] {
            guard let value = unit["value"] as? String,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            hasContent = true
        }
        for field in ["variations", "substitutions"] {
            if let children = translation[field] as? [String: Any] {
                guard !children.isEmpty else { return false }
                for child in children.values {
                    guard let object = child as? [String: Any] else { return false }
                    if field == "variations" {
                        guard !object.isEmpty else { return false }
                        for variant in object.values {
                            guard let value = variant as? [String: Any], hasValues(value) else { return false }
                        }
                    } else if !hasValues(object) {
                        return false
                    }
                }
                hasContent = true
            }
        }
        return hasContent
    }
}
