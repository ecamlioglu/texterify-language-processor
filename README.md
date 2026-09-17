# Texterify Renamer

**Your Texterify export, ready for your app.**

A small native macOS app that lives in your menu bar. Drop in a Texterify ZIP, preview the filename changes, and save an archive with the names your project expects. A soft Liquid Glass interface keeps the everyday workflow simple.

[**Download for macOS**](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0) · [User wiki](docs/wiki/README.md) · [Report an issue](https://github.com/ecamlioglu/texterify-language-processor/issues/new/choose)

[![macOS 27+](https://img.shields.io/badge/macOS-27%2B-7563BC)](docs/wiki/Installation.md)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-arm64-7563BC)](docs/wiki/Installation.md)
[![macOS build](https://github.com/ecamlioglu/texterify-language-processor/actions/workflows/macos.yml/badge.svg)](https://github.com/ecamlioglu/texterify-language-processor/actions/workflows/macos.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Install and start

1. Download **Texterify-Renamer-1.1.0-arm64.zip** from the [macOS release](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0).
2. Unzip it and move **Texterify Renamer.app** into **Applications**.
3. Open the app and click its menu bar icon.

The release is **Developer ID signed and notarized by Apple**. It requires **macOS 27 or later on Apple Silicon**. You do not need Python, Xcode, a terminal, or a Texterify account connection. The current interface is in Turkish; the wiki includes the exact button labels.

> Choose the release marked **Texterify Renamer … (macOS)**. GitHub's repository-wide “Latest” currently points to the separate legacy Python release.

## Drop. Preview. Save.

1. Drop your Texterify ZIP onto the menu bar icon or open the panel and choose **Dosya seç**.
2. Review the proposed renames. Open **Eşleştirmeler** to adapt the mappings to your project.
3. Select **ZIP’i indir**, choose an output folder when prompted, and use **Finder’da göster** to reveal the result.

For example, mapping `en` to `english.json` turns `en.json` into `english.json` inside the output ZIP. Translation contents stay the same; unmatched files keep their names and folders. The source ZIP is preserved.

## Made for a small, repeatable task

- **Native Liquid Glass.** A compact menu bar panel, soft accents, and System, Light, and Dark appearances.
- **Mappings you can manage.** Search and edit mappings, preview JSON, or import and export a configuration.
- **Clear output.** Preview changes before saving; choose a folder, filename prefix, and date format.
- **Existing files stay safe.** The Mac app creates a new output name or lets you cancel instead of overwriting a file.
- **Local processing.** ZIP conversion runs on your Mac. Optional update checks connect to GitHub.
- **Updates in the app.** Use **Tercihler → Güncellemeleri denetle…**. Automatic checks are optional; installation remains your choice.

[Try the sample export](examples/README.md) · [Configure mappings](docs/wiki/Configuration.md) · [Learn about updates](docs/wiki/Updates.md)

## Documentation

| I want to… | Start here |
| --- | --- |
| Install or use the Mac app | [User wiki](docs/wiki/README.md) |
| Change mappings and output names | [Configuration](docs/wiki/Configuration.md) |
| Resolve a problem | [Troubleshooting](docs/wiki/Troubleshooting.md) |
| Build or contribute | [Contributing](CONTRIBUTING.md) |
| Sign and publish a release | [macOS maintainer guide](macos/README.md) |
| See what has actually been tested | [Validation record](docs/MAC_APP_VALIDATION.md) |

## Legacy Python package

Prefer a script, a build pipeline, Windows, or Linux? The **Texterify Language Processor** CLI and Python library remain available in this repository. The native app has its own Swift implementation and does not run Python.

The legacy Python package keeps its independent **2.1.0** version. Use the current repository source for the reusable `process_archive(...)` API; older Python release assets predate that API.

[**Legacy Python wiki →**](docs/wiki/Legacy-Python.md)

## Open source

Built with SwiftUI, AppKit, [ZIPFoundation](https://github.com/weichsel/ZIPFoundation), and [Sparkle](https://github.com/sparkle-project/Sparkle). Released under the [MIT License](LICENSE).

Processing checks live in the [Swift tests](macos/Tests/RenamerCoreTests/) and [Python tests](tests/); see the validation record above for native UI and release checks.

The repository keeps its original `texterify-language-processor` URL so existing links and Python workflows continue to work.
