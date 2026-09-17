# Updates

[Wiki home](README.md) · [Troubleshooting](Troubleshooting.md)

## Check now

Open **Tercihler → Güncellemeleri denetle…**. The app shows **Uygulama güncel!** when it is current. When a newer version is available, follow the dialog to download, install, and relaunch.

Finish processing and save/close the mappings editor before relaunching. An update waits while those activities are open.

## Automatic checks

**Güncellemeleri otomatik denetle** is off by default. Turn it on for periodic checks. Scheduled updates appear as a reminder inside the panel; download and installation remain your choice.

ZIP processing stays local. Update checks and downloads use GitHub and need an internet connection. No GitHub account or token is required.

## Update source

The app reads a dedicated [macOS feed](https://github.com/ecamlioglu/texterify-language-processor/releases/download/macos-updates/appcast.xml), independent of GitHub's repository-wide “Latest” Python release.

Public app releases use `macos-v<version>` tags. Both the feed and archives have Sparkle Ed25519 signatures. Public apps are also Developer ID signed and notarized by Apple.

The early 1.0.0 build has no updater. Quit it and replace it with [1.1.0](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0) once; later releases can use in-app updates.

Maintainers: see the [release guide](../../macos/README.md).
