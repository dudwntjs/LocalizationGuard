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

- `LG01`: UI-facing literal missing from a String Catalog
- `LG02`: Interpolated string requiring localization review
- `LG03`: Unknown explicit localization key
- `LG00`: Scan completion summary

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
  "excludedPaths": ["Tests", "Generated", "PreviewContent", ".build"],
  "ignoredFunctions": ["print", "debugPrint", "fatalError", "os_log"]
}
```

## Command-line usage

```sh
swift run LocalizationGuardCLI /path/to/your/project
```

When attached to an Xcode target, the plug-in runs automatically when its inputs change. It prints an `LG00` completion summary so you can verify that the scan ran.

## Current limitations

LocalizationGuard currently focuses on projects that use Korean source strings.

General string detection targets strings containing Korean characters. Explicitly supported SwiftUI APIs may be checked regardless of language.

The current version checks whether a key exists in a String Catalog, but does not verify that every locale has a translated value.

## License

LocalizationGuard is available under the MIT License.
