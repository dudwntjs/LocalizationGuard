# LocalizationGuard

[![Swift 6.1+](https://img.shields.io/badge/Swift-6.1%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/dudwntjs/LocalizationGuard?label=release&sort=semver)](https://github.com/dudwntjs/LocalizationGuard/tags)

**English** | [한국어](README_KO.md) | [日本語](README_JA.md)

A Swift build tool plug-in that finds localization gaps and reports them as clickable Xcode warnings.

LocalizationGuard compares user-facing strings in Swift source files with the keys in your String Catalogs. It consists of a small command-line scanner and a build tool plug-in that runs the scanner during builds.

## Requirements

- Swift 6.1 or later
- macOS 13 or later

## Installation

In Xcode, select **File → Add Package Dependencies** and enter:

```text
https://github.com/dudwntjs/LocalizationGuard
```

Add `LocalizationGuardPlugin` to your app target, then confirm that it appears under **Build Phases → Run Build Tool Plug-ins**.

## Rules

- `Missing translation`: UI-facing literal missing from a String Catalog
- `String interpolation`: Interpolated string requiring localization review
- `Unknown localization key`: Unknown explicit localization key
- `Missing language`: Missing or empty translation for a target language in a String Catalog
- `Localization summary` (note): Scan completion summary

Suppress an intentional finding with:

```swift
// localization-guard:disable-next-line
Text(verbatim: "HTTP")
```

## Configuration

Add `.localizationguard.json` to the root of the project being scanned. If `catalogs` is empty or omitted, LocalizationGuard discovers all `.xcstrings` files automatically.

```json
{
  "catalogs": ["Sources/Resources/Localizable.xcstrings"],
  "requiredLanguages": ["ko", "en", "ja"],
  "sourceLanguages": ["ko"],
  "excludedPaths": ["Tests", "Generated", "PreviewContent", ".build"],
  "ignoredFunctions": ["print", "debugPrint", "fatalError", "os_log"]
}
```

By default, target languages are inferred independently from the locales present in each catalog. Set `requiredLanguages` to check an explicit set, including a language with no translations yet. Missing entries and empty or whitespace-only values emit `Missing language` warnings linked to the catalog. The source language uses the key as a fallback; entries marked `shouldTranslate: false` or `stale` are skipped. Existing plural/device variants and substitutions are checked for empty values.

## Command-line usage

```sh
swift run LocalizationGuardCLI /path/to/your/project
```

When attached to an Xcode target, the plug-in runs automatically when its inputs change. It prints an `Localization summary` completion summary so you can verify that the scan ran.

## Current limitations

LocalizationGuard detects Korean source strings by default. Set `sourceLanguages` to `["ja"]` for Japanese source strings, or specify both languages when a project contains both. Supported values are `ko` and `ja`.

General string detection targets characters in the configured source languages. Explicitly supported SwiftUI APIs may be checked regardless of language.

The scanner checks key presence and missing/empty per-language values. It does not judge translation quality, review status, or whether all language-specific plural categories are present. If a required language does not appear anywhere in a catalog yet, declare it with `requiredLanguages`.

## License

LocalizationGuard is available under the MIT License.
