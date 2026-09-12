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

- `Missing translation`: 사용자 노출 가능성이 있는 문구가 String Catalog에 없음
- `String interpolation`: 문자열 보간에 로컬라이제이션 확인이 필요함
- `Unknown localization key`: 코드에서 사용한 로컬라이제이션 키가 존재하지 않음
- `Missing language`: 카탈로그 키는 있지만 특정 언어의 번역이 없거나 비어 있음
- `Localization summary` (note): 검사 완료 결과 요약

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
  "requiredLanguages": ["ko", "en", "ja"],
  "sourceLanguages": ["ko"],
  "excludedPaths": ["Tests", "Generated", "PreviewContent", ".build"],
  "ignoredFunctions": ["print", "debugPrint", "fatalError", "os_log"]
}
```

기본적으로 각 카탈로그에 존재하는 언어를 검사 대상으로 추론합니다. `requiredLanguages`로 언어를 지정하면 아직 번역이 하나도 없는 언어도 검사합니다. 번역 항목이 없거나 값이 빈 문자열/공백이면 카탈로그로 연결되는 `Missing language` 경고를 출력합니다. 원문 언어는 키 자체를 기본값으로 사용하므로 별도 번역을 요구하지 않습니다. `shouldTranslate: false` 또는 `stale` 항목은 제외하며, 등록된 복수형·기기별 변형과 치환 문자열의 빈 값도 검사합니다.

## 명령줄에서 실행

```sh
swift run LocalizationGuardCLI /path/to/your/project
```

Xcode Target에 플러그인을 연결하면 입력 파일이 변경된 후 빌드할 때 검사가 자동으로 실행됩니다. 검사가 실행되었는지는 `Localization summary` 요약 메시지로 확인할 수 있습니다.

## 현재 제한 사항

LocalizationGuard는 기본적으로 한국어 원문 문자열을 탐지합니다. 일본어 원문 프로젝트는 `sourceLanguages`를 `["ja"]`로 설정하고, 두 언어가 함께 있는 프로젝트는 둘 다 지정할 수 있습니다. 현재 지원하는 값은 `ko`, `ja`입니다.

일반 문자열 탐지는 설정한 원문 언어의 문자를 포함한 문자열을 대상으로 하며, 명시적으로 지원하는 SwiftUI API는 언어와 관계없이 검사될 수 있습니다.

키 존재 여부와 언어별 번역 누락·빈 값을 검사합니다. 번역의 품질, 검토 상태, 언어별 모든 복수형 범주의 존재 여부까지 판단하지는 않습니다. 카탈로그 전체에 없는 언어는 자동 추론할 수 없으므로 `requiredLanguages`로 지정해야 합니다.

## 라이선스

LocalizationGuard는 MIT License로 배포됩니다. 자유롭게 사용·수정·배포할 수 있지만 저작권과 라이선스 문구를 유지해야 하며, 제작자는 사용 결과를 보증하지 않습니다.
