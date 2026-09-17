# Texterify Renamer — macOS maintainer guide

Native macOS 27+ menu bar app, in the same repository as the Python library. ZIP processing runs offline; optional update checks use GitHub. No Python installation is needed by the Mac app.

**Looking to use the app?** [Download the signed release](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0) and follow the [user wiki](../docs/wiki/README.md). This page is for building, signing and maintaining the native app. The [legacy Python guide](../docs/wiki/Legacy-Python.md) covers the separate CLI/library.

## Application identity

The bundle identifier and logging subsystem are `com.erdemdev.texterifyrenamer`. The visible application name remains **Texterify Renamer**. This identifier is separate from the Developer ID certificate used to sign a public release. Repository URLs continue to use the actual GitHub repository owner.

Changing a sandboxed app's bundle ID creates a separate settings/container identity. Previous local development config and preferences are left intact in `~/Library/Containers/com.ecamlioglu.texterify-renamer/Data/`; they are not silently migrated or deleted. To keep a custom config, import its `Library/Application Support/TexterifyRenamer/config.json` through the editor's JSON import. Re-select the output folder in the new app to grant its own permission; do not copy the previous app's security-scoped bookmark. Other preferences can be selected again in the menu panel.

GitHub distribution uses a ZIP containing the `.app`, with a separate [Developer ID signing and notarization](https://developer.apple.com/developer-id/) step. The build script defaults to a local ad-hoc signature and does not publish or notarize releases.

## Signed ZIP distribution

Create a **Developer ID Application** certificate in Xcode's Apple Accounts settings. A paid individual membership is sufficient. Verify its identity with `security find-identity -v -p codesigning`. Use the certificate's team, which can differ from other development teams on the Mac.

Store notarization credentials once in your own Terminal. Replace the example email with the Apple Account enrolled in the Developer Program. The command securely prompts for an [app-specific password](https://support.apple.com/102654); never put that password in a command, repository, or chat.

```sh
xcrun notarytool store-credentials texterify-renamer \
  --apple-id 'YOUR_APPLE_ACCOUNT_EMAIL' --team-id P3M6R3G2A6
```

Build and notarize from the repository root, with the app closed:

```sh
swift test --package-path macos
SIGNING_IDENTITY='Developer ID Application: Selim Erdem Camlioglu (P3M6R3G2A6)' \
  bash scripts/build-macos.sh release
NOTARY_PROFILE=texterify-renamer TEAM_ID=P3M6R3G2A6 bash scripts/notarize-macos.sh
```

The signing script adds Hardened Runtime and a secure timestamp. The notarization script checks the certificate/team, submits a copy of the signed app to Apple, requires `Accepted`, staples the ticket to the app, checks Gatekeeper, and creates a fresh ZIP. It extracts that final ZIP to verify the signature and stapled ticket again, and writes `SHA256SUMS.txt`. ZIP files cannot themselves be stapled.

Only successful runs create `dist/releases/Texterify-Renamer-<version>-<arch>/`. Existing release directories are never overwritten. Submission files and JSON responses stay in ignored `dist/notarization/` for diagnosis. A timeout does not cancel Apple's processing: inspect the submission ID using `xcrun notarytool info <id> --keychain-profile texterify-renamer` before resubmitting. Building and notarizing do not publish; the separate publication script is described below.

Before publishing, test the ZIP after a browser download on another Mac: unzip, move the app into Applications, open, drop a ZIP, save a mapping and export, then reopen to check persisted settings. Current builds require **macOS 27+**; an arm64 ZIP supports **Apple Silicon**. Local signing and Gatekeeper checks do not replace this clean-install test. Use a separate `macos-v1.1.0` release tag. The Python workflow now skips macOS release events; those workflow changes must be included in the source commit before publishing.

## In-app updates and GitHub releases

Version 1.1.0 includes Sparkle 2.10.0, pinned in Package.swift/Package.resolved. Preferences and the application/status context menus expose **Güncellemeleri denetle…**. Automatic checks are opt-in; scheduled updates appear as a quiet button in the panel. Downloads/installations require user action. Relaunch waits for processing to finish and for the mappings editor to close, so its draft can be saved first.

The stable feed is `https://github.com/ecamlioglu/texterify-language-processor/releases/download/macos-updates/appcast.xml`. It is independent of GitHub's repository-wide Latest release, which is also used by the Python library. Every app ZIP has an immutable `macos-v<version>` release URL. The feed and ZIP both require Sparkle Ed25519 signatures; archive signatures are checked before extraction. Sparkle's installer XPC service is enabled for sandboxed app replacement. App/config identity remains unchanged across updates.

The private update signing key is stored in the local login Keychain under account `com.erdemdev.texterifyrenamer`. Only its public key is embedded in Info.plist. Preserve this key in your normal secure Keychain backup; do not regenerate it for each release or export it into this repository. Developer ID and notarization credentials are separate.

For each release:

1. Increase both `CFBundleShortVersionString` and the integer `CFBundleVersion`. Never replace a ZIP already downloaded by users.
2. Commit/review the intended source changes and push a matching `macos-v<version>` tag. Python releases continue using `v<version>`; the Python workflow skips macOS release events.
3. Build with Developer ID and run `notarize-macos.sh` as above. Then run:

   ```sh
   bash scripts/prepare-macos-update.sh dist/releases/Texterify-Renamer-1.1.0-arm64
   ```

   This generates/signs `appcast.xml` using the final notarized ZIP, verifies the signing key matches the app and checks version, build, URL and byte count. Do not edit the resulting XML by hand.

4. After reviewing/testing the exact ZIP, explicitly publish:

   ```sh
   bash scripts/publish-macos-release.sh dist/releases/Texterify-Renamer-1.1.0-arm64
   ```

   This requires committed app/config/scripts/workflows and an existing remote tag at HEAD. It refuses a non-increasing build compared with the current signed feed. It creates/uploads a draft version release, publishes it without changing Python's Latest designation, downloads and compares the public ZIP, then replaces the stable feed asset **last**. Both feed and public ZIP bytes are verified. A published version ZIP is never overwritten; after a partial publication, the script can continue only if its public ZIP equals the local one and the feed has not yet advanced. If feed upload succeeded but its CDN verification was stale, compare the public feed after cache expiry rather than uploading another version blindly.

5. Verify **Güncellemeleri denetle…** from an older installed version against the public GitHub endpoint. Local update testing does not prove GitHub CDN availability.

The original 1.0.0 build has no updater and must be replaced manually once. No GitHub credentials are shipped in the app. Developer ID signing/notarization/keychain access remains local; CI artifacts are development builds, not public update packages. Version 1.1.0 is published; future releases use the explicit process above with a new version/build and release directory.

## Build and open

Requires Xcode 27 / Swift 6.4 and the macOS 27 SDK. The package uses Swift 6 language mode. The first build downloads pinned ZIPFoundation 0.9.20 and Sparkle 2.10.0. GitHub Actions explicitly uses the `xcode-27` runner and validates the toolchain before testing and packaging.

```sh
bash scripts/build-macos.sh release
open 'dist/Texterify Renamer.app'
```

The script creates an ad-hoc signed, sandboxed `.app` for local use. It can be copied to Applications. Do not rebuild while using the app. For distribution, provide `SIGNING_IDENTITY` with a Developer ID identity and notarize/staple the result separately. No certificate or notarization is configured automatically. The script builds for the current Mac's architecture; it does not claim Intel validation.

The status icon lives in the macOS menu bar, with no persistent Dock icon. Click it to open the panel, or drop one ZIP onto the icon. The panel also accepts a ZIP or opens a native file picker. Finder's Open With is supported without making this app the default ZIP handler.

1. Drop/select a Texterify ZIP.
2. Review the count and optional list of changes.
3. Select **ZIP’i indir**. On the first use choose an output folder; that permission is remembered.
4. Use **Finder’da göster** to find the saved ZIP.

**Farklı kaydet…** opens a save dialog. Existing files are never replaced, even if a save dialog offers replacement. Choose a new name; the normal download action adds `_1`, `_2`, etc. automatically. The source ZIP is always preserved.

## Settings

**Eşleştirmeler** edits language codes and target filenames. Import, export, and read-only JSON preview are included. Imported configs remain drafts until **Kaydet**. **Varsayılanı yükle** likewise loads a draft without silently replacing the saved config. Validation errors leave the active config intact.

**Tercihler** (the slider button) stays inside the menu panel: output folder, save behavior, file prefix/date and system/light/dark appearance. Naming applies with **Uygula**; the other preferences apply immediately.

Only **Eşleştirmeler** opens a larger app window. Search filters the editable list; the braces button shows the current draft as JSON in the same window. Case sensitivity belongs to this draft. **Geri al** resets the draft; **Kaydet** validates and activates it. The **Config** menu imports/exports JSON and loads the bundled default. Import/default also includes output naming; ordinary mapping edits preserve the latest naming preferences.

The active config is stored in Application Support/TexterifyRenamer inside the sandbox container. UI preferences and the security-scoped output-folder bookmark are separate. If a saved config is invalid, the app displays the error and requires a valid import or explicit reset.

`config/language_mappings.json` is the repository's authoritative default. The app's resource copy must match it; the build script and CI check this. After editing defaults, copy it to `macos/Sources/RenamerCore/Resources/default-config.json`.

## Design and platform

The menu surface uses AppKit `NSGlassEffectView`. SwiftUI `glassEffect`, interactive glass, `GlassEffectContainer`, `.glass` and `.glassProminent` provide native navigation and action surfaces. The larger editor uses a system backdrop with glass controls and a quieter content area. No third-party UI kit or simulated gradient blur is used. On native macOS the UI frameworks are SwiftUI and AppKit; UIKit is for the iOS family.

The state model uses Observation (`@Observable`, `@Bindable`); immutable processing snapshots conform to `Sendable` for Swift 6 concurrency. System materials follow appearance and accessibility preferences, and panel transitions check Reduce Motion. macOS 13–26 are no longer deployment targets.

Design references: [Apple WWDC26: What’s new in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/), [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials). API availability was also checked against the installed macOS 27 SDK.

## Supported behavior

- Match the final-extension stem, optionally case-sensitive; preserve nested paths and unrelated file bytes.
- Preserve unknown top-level config annotations during import/export.
- Supported date patterns: `%d_%m`, `%Y%m%d`, `%Y-%m-%d`, `%Y-%m-%d_%H%M`.
- `preserve_extensions=true`, `backup_original=true`, unknown processing settings, or a non-ZIP output extension are rejected explicitly.
- Reject duplicate/unsafe paths, target collisions, symlinks, corrupt and encrypted archives, multi-volume ZIP and ZIP64.
- Limits: 100 MiB compressed input, 500 MiB expanded payload, 10,000 entries.
- Detect input changes after preview, support cancellation, and publish a fully verified output without replacing existing files.
- Preserve file payloads and relative paths; ZIP byte order, timestamps, compression and permissions are not a fidelity contract.

## Structure and tests

```text
Sources/RenamerCore/        Config, inspection and export; no UI dependency
Sources/TexterifyRenamer/   AppKit status/drop host, SwiftUI panel and settings
Tests/RenamerCoreTests/     Real sample, shared contract and failure cases
Packaging/                 App metadata, sandbox entitlements and icon generator
```

```sh
swift test --package-path macos
python3 tests/run_tests.py
```

Both implementations read `tests/fixtures/export.zip`, `config.json`, and `expected.json`. The full real sample test runs when the user's September 16 ZIPs are available; it explicitly skips on a clean checkout without those local files. The shared fixture always runs.

Local signing/build and core tests do not prove UI interactions, notarization, Intel compatibility or older macOS behavior. See `docs/MAC_APP_VALIDATION.md` for actual checks performed.

The soft palette is centralized in `Design.swift` (`AppPalette` and `SoftBackdrop`): lavender actions, sage success, native text colors and appearance-aware backgrounds. The editor has a real unified macOS titlebar/toolbar with Save, bridged from SwiftUI. Its initial position is the center of the active status item's display; the menu popover includes additional space below its anchor.

Menu placement is managed by `MenuBarPanel.swift`. A transparent one-point anchor window positions the native popover 12 pt below the menu bar, keeping its system chevron visible. Startup placeholder status-item coordinates are rejected. Content height changes preserve this anchor; oversized content scrolls within the available screen area. This replaces the earlier offset applied directly to the status button's positioning rectangle.
