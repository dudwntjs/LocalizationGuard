# LocalizationGuard

[![Swift 6.1+](https://img.shields.io/badge/Swift-6.1%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/dudwntjs/LocalizationGuard?label=release&sort=semver)](https://github.com/dudwntjs/LocalizationGuard/tags)

[English](README.md) | **한국어** | [日本語](README_JA.md)

Swift 코드에서 로컬라이제이션 누락을 찾아 클릭 가능한 Xcode 경고로 표시하는 Swift 빌드 도구 플러그인입니다.

LocalizationGuard는 Swift 코드의 사용자 노출 문자열과 String Catalog의 키를 비교합니다. 실제 검사는 명령줄 검사기가 담당하고, 빌드 도구 플러그인이 Xcode 빌드 중 검사기를 자동으로 실행합니다.

## 요구 사항

- Swift 6.1 이상
- macOS 13 이상

## 설치

Xcode에서 **File → Add Package Dependencies**를 선택하고 다음 주소를 입력합니다.

```text
https://github.com/dudwntjs/LocalizationGuard
```

앱 Target에 `LocalizationGuardPlugin`을 추가한 뒤 **Build Phases → Run Build Tool Plug-ins**에 표시되는지 확인합니다.

## 경고 종류

- `LG01`: 사용자 노출 가능성이 있는 문구가 String Catalog에 없음
- `LG02`: 문자열 보간에 로컬라이제이션 확인이 필요함
- `LG03`: 코드에서 사용한 로컬라이제이션 키가 존재하지 않음
- `LG00`: 검사 완료 결과 요약

의도적으로 검사에서 제외할 문구는 다음처럼 표시합니다.

```swift
// localization-guard:disable-next-line
Text(verbatim: "HTTP")
```

## 설정

검사할 프로젝트의 최상위 폴더에 `.localizationguard.json`을 추가합니다. `catalogs`가 비어 있거나 생략되면 모든 `.xcstrings` 파일을 자동으로 찾습니다.

```json
{
  "catalogs": ["Sources/Resources/Localizable.xcstrings"],
  "excludedPaths": ["Tests", "Generated", "PreviewContent", ".build"],
  "ignoredFunctions": ["print", "debugPrint", "fatalError", "os_log"]
}
```

## 명령줄에서 실행

```sh
swift run LocalizationGuardCLI /path/to/your/project
```

Xcode Target에 플러그인을 연결하면 입력 파일이 변경된 후 빌드할 때 검사가 자동으로 실행됩니다. 검사가 실행되었는지는 `LG00` 요약 경고로 확인할 수 있습니다.

## 현재 제한 사항

LocalizationGuard는 현재 한국어 원문을 사용하는 프로젝트를 중심으로 검사합니다.

일반 문자열 탐지는 한글이 포함된 문자열을 대상으로 하며, 명시적으로 지원하는 SwiftUI API는 언어와 관계없이 검사될 수 있습니다.

현재 버전은 String Catalog에 키가 존재하는지 확인하지만, 각 언어의 번역 값이 비어 있는지까지 검사하지는 않습니다.

## 라이선스

LocalizationGuard는 MIT License로 배포됩니다. 자유롭게 사용·수정·배포할 수 있지만 저작권과 라이선스 문구를 유지해야 하며, 제작자는 사용 결과를 보증하지 않습니다.
