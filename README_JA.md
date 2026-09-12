# LocalizationGuard

[![Swift 6.1+](https://img.shields.io/badge/Swift-6.1%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/dudwntjs/LocalizationGuard?label=release&sort=semver)](https://github.com/dudwntjs/LocalizationGuard/tags)

[English](README.md) | [한국어](README_KO.md) | **日本語**

ローカライズ漏れを検出し、クリック可能な Xcode 警告として報告する Swift ビルドツールプラグインです。

LocalizationGuard は、Swift ソースコード内のユーザー向け文字列と String Catalog 内のキーを比較します。小さなコマンドラインスキャナーと、ビルド中にスキャナーを実行するビルドツールプラグインで構成されています。

## 必要要件

- Swift 6.1 以降
- macOS 13 以降

## インストール

Xcode で **File → Add Package Dependencies** を選択し、次のアドレスを入力します。

```text
https://github.com/dudwntjs/LocalizationGuard
```

アプリターゲットに `LocalizationGuardPlugin` を追加し、**Build Phases → Run Build Tool Plug-ins** に表示されていることを確認します。

## 警告の種類

- `Missing translation`: ユーザー向け文字列が String Catalog にありません
- `String interpolation`: 文字列補間のローカライズ確認が必要です
- `Unknown localization key`: コードで使用しているローカライズキーが存在しません
- `Missing language`: カタログキーはありますが、特定言語の翻訳がないか空です
- `Localization summary` (note): スキャン完了結果の要約

意図的に検査から除外する文字列には、次のように指定します。

```swift
// localization-guard:disable-next-line
Text(verbatim: "HTTP")
```

## 設定

検査するプロジェクトのルートフォルダに `.localizationguard.json` を追加します。`catalogs` が空、または省略されている場合、すべての `.xcstrings` ファイルを自動的に検出します。

```json
{
  "catalogs": ["Sources/Resources/Localizable.xcstrings"],
  "requiredLanguages": ["ko", "en", "ja"],
  "sourceLanguages": ["ko"],
  "excludedPaths": ["Tests", "Generated", "PreviewContent", ".build"],
  "ignoredFunctions": ["print", "debugPrint", "fatalError", "os_log"]
}
```

デフォルトでは、各カタログに存在する言語を検査対象として推測します。`requiredLanguages` を指定すると、まだ翻訳が一つもない言語も検査できます。翻訳項目がない場合や値が空文字列・空白のみの場合は、カタログにリンクする `Missing language` 警告を出力します。ソース言語はキーそのものをフォールバックとして使用するため、別途翻訳は必要ありません。`shouldTranslate: false` または `stale` の項目は除外され、登録済みの複数形・デバイス別バリエーション・置換文字列の空の値も検査します。

## コマンドラインで実行

```sh
swift run LocalizationGuardCLI /path/to/your/project
```

Xcode ターゲットにプラグインを接続すると、入力ファイルの変更後にビルドしたとき自動的にスキャンが実行されます。スキャンが実行されたことは、`Localization summary` の要約メッセージで確認できます。

## 現在の制限事項

LocalizationGuard はデフォルトで韓国語のソース文字列を検出します。日本語のソース文字列を検査するには、`.localizationguard.json` の `sourceLanguages` を変更します。両方の言語を含むプロジェクトでは、両方を指定できます。現在サポートしている値は `ko` と `ja` です。

```json
{
  "sourceLanguages": ["ja"]
}
```

韓国語のソース文字列には `["ko"]` を使用し、両方の言語を使用するプロジェクトでは `["ko", "ja"]` を設定します。

一般的な文字列検出は、設定したソース言語の文字を含む文字列を対象としています。明示的に対応する SwiftUI API は、言語に関係なく検査される場合があります。

キーの存在と、言語ごとの翻訳漏れ・空の値を検査します。翻訳の品質、レビュー状態、言語ごとのすべての複数形カテゴリの存在までは判断しません。カタログ内にまだ一つも存在しない必須言語は、`requiredLanguages` で明示的に指定する必要があります。

## ライセンス

LocalizationGuard は MIT License で提供されています。著作権およびライセンス表記を維持する限り、自由に使用・変更・配布できます。作成者は利用結果を保証しません。
