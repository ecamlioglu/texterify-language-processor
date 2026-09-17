# Install Texterify Renamer

[Wiki home](README.md) · [Next: daily workflow](Usage.md)

## Requirements

| | Current macOS release |
| --- | --- |
| System | macOS 27 or later |
| Hardware | Apple Silicon (arm64) |
| Version | 1.1.0, build 4 |
| Interface | Turkish |
| Python or Xcode | Not required |

The download is not an Intel build. For Windows, Linux, or a Mac that does not meet these requirements, see [Legacy Python](Legacy-Python.md).

## Download and open

1. Open the [macOS release page](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0).
2. Download **Texterify-Renamer-1.1.0-arm64.zip** from Assets. GitHub's “Source code” archives are for developers.
3. Unzip and move **Texterify Renamer.app** to **Applications**.
4. Open it, then click its icon in the menu bar. There is no persistent Dock icon.

The public ZIP contains a Developer ID signed app with an Apple notarization ticket. The release includes `SHA256SUMS.txt` for optional download verification.

You do not sign into Texterify inside the app. Export a ZIP from Texterify, then give that file to Renamer.

## First use

Check that the target filenames in the mappings editor match your project. The bundled configuration is a starting point, not a universal set of Texterify IDs.

On the first save, select a destination folder in the native dialog. This grants the app access to that folder. Change it later under **Tercihler**.

Already using the early 1.0.0 app? Quit it and replace it with 1.1.0 once. Version 1.0.0 did not have an updater. See [Updates](Updates.md).
