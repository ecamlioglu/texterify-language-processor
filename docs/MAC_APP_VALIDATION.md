# macOS MVP validation — 2026-09-16

> Engineering history: entries below describe successive checkpoints and can supersede earlier results. For current installation and use, read the [Texterify Renamer wiki](wiki/README.md). The latest completed checks are the CI recovery and native public-feed sections at the end.

Environment: Apple Silicon, macOS 27.0 (26A428), Xcode 27.0, Swift 6.4. The initial MVP targeted macOS 13. The later Liquid Glass redesign below raises the deployment target to macOS 27; the initial MVP checks in this section are historical.

## Verified

| Check | Result |
| --- | --- |
| `python3 tests/run_tests.py` | PASS — 22 tests |
| Black, isort and flake8 on `src/` and `tests/` | PASS |
| `git diff --check` | PASS |
| `swift test --package-path macos` | PASS — 12 XCTest cases, including local real sample and shared fixture |
| `bash scripts/build-macos.sh release` | PASS — native release executable and locally signed sandboxed app |
| `codesign --verify --strict` | PASS — local ad-hoc signature; not Developer ID/notarization |
| Build Python wheel | PASS |
| Build sdist and build wheel from sdist | PASS |
| Install wheel in isolated virtual environment; run CLI outside repository | PASS |
| Installed Python `process_archive` outside repo | PASS — silent/non-interactive, bundled default including French |
| Open native app | PASS — actual panel visually inspected |
| Native file picker + real 11-language ZIP preview | PASS |
| First download, native folder permission, save to Downloads | PASS — app displayed `Kaydedildi / lang_files_16_09.zip` |
| Native save-as to a different folder | PASS — `dist/native-ui-check.zip` created |
| Independently inspect native save-as ZIP | PASS — all 11 names and decompressed file bytes match provided output |
| Native config duplicate-key validation | PASS — duplicate `ar` rejected before saving |
| Native config revert and save | PASS — original 11 mappings restored and saved; preview recomputed |
| Native settings layout | PASS — mapping and output tabs visually inspected |
| Native collision preview | PASS — subsequent preview proposes `lang_files_16_09_1.zip` |

## Not yet verified

- Physical Finder drag onto the menu bar icon and onto the panel. Both handlers are implemented, but native UI automation verified the file-picker route, not an actual cross-window drag.
- Multi-monitor/full-screen status item placement and VoiceOver use.
- Theme switching and config import/export through the native dialogs (core config round-trip is tested).
- Restart persistence of the security-scoped folder bookmark and revoked permissions.
- Disk-full failure on a real volume; cancellation and output preservation are covered by core tests.
- Intel or macOS 13–26 runtime behavior.
- Developer ID signing, notarization and execution on a different clean Mac.
- Remote GitHub Actions execution. The workflow was added locally only.

The terminal could not read the Downloads output because of macOS privacy restrictions, even outside the execution sandbox. Its save success is UI evidence only. Independent byte comparison used the second output written through the native save panel into `dist/`, where the terminal has access.

## Deliverables and state

- App: `dist/Texterify Renamer.app` (local ARM64 release, approximately 1.6 MiB).
- Native UI test output: `dist/native-ui-check.zip`.
- First native output: `~/Downloads/lang_files_16_09.zip`.
- The app's selected folder is Downloads and the original Doktar config is active.
- The user-provided source/output ZIPs remain in `src/`; older deleted ZIPs were not restored.
- No commit, push, remote repository, or published release was created.
- Finder changed tracked `.DS_Store` files during UI verification; these metadata changes were left untouched.

Real sample fingerprints at verification:

```text
Doktar App-16-09-2026-1789557129283.zip
d201f8980b602ade74b4bafedbbb8896ce3ba788d1ee8928a39eed2cc6dd782b

lang_files_16_09.zip (provided reference)
5760befbacdb1d2bbbf019fb30db3adeef4bb75d71bdca1520ae2c761b6c2d93
```

## Liquid Glass redesign — 2026-09-16

This revision targets **macOS 27**, uses **Xcode 27 / Swift 6.4 / Swift 6 language mode**, and pins **ZIPFoundation 0.9.20**. Earlier platform assumptions above are superseded.

- PASS: Swift debug build and 12 core XCTest cases after migration, including metadata preservation and real sample parity.
- PASS: Release app packaged and its local ad-hoc signature verified.
- PASS: Native Liquid Glass menu surface visually inspected; routine preferences remain inside this panel.
- PASS: Expanded mapping editor, live search (`fr` leaves only the French mapping), and inline JSON preview inspected through native UI.
- PASS: Dark appearance checked on both the panel and editor. Final native verification also confirmed dark → System switches back to the system’s light appearance without restarting. Appearance is resolved explicitly and follows NSApplication effective-appearance changes. The final preference is System.
- PASS: Final editor uses a full-size content view; the titlebar backdrop is continuous with the content.
- PASS: Executable `LC_BUILD_VERSION` reports both minimum OS and SDK 27.0.
- PASS: Native file picker loaded the real 11-language sample; preview used the remembered Downloads folder after app restart.
- PASS: Native save-as wrote `dist/lang_files_16_09_1.zip`; independent Python ZIP inspection confirmed all 11 entry names and decompressed payloads exactly match `src/lang_files_16_09.zip`.
- PASS: `git diff --check`.

The UI uses actual `NSGlassEffectView`, SwiftUI glass styles and interactive glass, with system materials for the editor content. Reduce Motion is consulted for panel transitions; full VoiceOver, Increase Contrast and Reduce Transparency interaction testing is still NOT_RUN. Physical drag/drop, native JSON import/export, remote CI and distribution/notarization remain NOT_RUN. CI now fails clearly when its runner lacks SDK 27; no remote run was performed.

Python code and user source archives were not modified by the redesign. No commit or push was performed.

## Soft palette, placement and native titlebar — 2026-09-16

- Added a shared adaptive lavender accent and sage success color, a lightly tinted glass panel, and soft canvas/content surfaces. Text keeps native primary/secondary colors.
- Restored a visible native window title/subtitle and unified toolbar using `NSHostingController.sceneBridgingOptions = [.toolbars]`. Save now lives in the actual macOS toolbar, not a body header.
- Adjusted the popover anchor 12 points downward, accounting for flipped status-button coordinates. The expanded editor is geometrically centered on the status item's screen visible frame, with a 24-point safety inset; it no longer uses AppKit's higher optical centering when a screen is available.
- PASS: debug build, release packaging, and local signature verification.
- PASS: native screenshots inspected for the pastel menu panel and editor, including visible traffic-light buttons, title/subtitle and toolbar Save.
- PASS: clicked Save in the native toolbar and observed `Config kaydedildi.` with the original config intact.
- PASS: `git diff --check`.
- No processing/config schema changes. Core tests were not repeated for this visual-only revision; earlier 12-case result remains the latest core run.
- Multi-monitor/full-screen placement, native window dragging, and this palette's dark-mode appearance remain NOT_RUN in this revision.

## Menu-bar anchoring correction — 2026-09-16

Supersedes the previous 12-point status-button rectangle offset, which did not prevent the reported overlap.

- `MenuBarPanel.swift` now anchors the native NSPopover to a transparent, mouse-ignoring one-point window explicitly placed below the status item. The native chevron points toward the item, and native appearance/dismissal behavior is retained.
- Rejects temporary startup geometry (observed status-item window `{0, 0, 46, 0}` with button coordinates below the screen) and retries presentation briefly after AppKit layout.
- Places the anchor 12 points below the menu-bar bottom. Caps the content viewport to available height and scrolls oversized content instead of forcing placement above the anchor. Display-configuration changes dismiss the panel so reopening obtains fresh coordinates.
- PASS: release build and strict ad-hoc signature validation; `git diff --check`.
- PASS: native visual inspection of the menu panel and expanded real-ZIP preview; original pastel/glass appearance preserved.
- PASS: native preferences → back → file picker → real ZIP preview → expanded changes list.
- PASS: runtime geometry logs for final process 12533 showed `menuBottom=1074`, `panelTop=1062`, and `anchorTip=1062` throughout. Empty panel bottom was 665, preferences bottom 529, expanded preview bottom 501. Thus the upper edge remained 12 points below the menu bar while the body resized downward.
- No source archive/config changes or output writes in this correction. Processing tests were not repeated because the processing code is unchanged.
- Other screen configurations, auto-hidden menu bar/full-screen runtime, and physical dragging remain NOT_RUN.

## Application identity — 2026-09-16

- Changed CFBundleIdentifier and both OSLog subsystems to `com.erdemdev.texterifyrenamer`. Display name and real GitHub repository URLs are unchanged.
- PASS: release build, Info.plist syntax validation, and `git diff --check`.
- PASS: packaged Info.plist and `codesign -dv --verbose=2` both report `com.erdemdev.texterifyrenamer`; strict signature verification passes. Signature remains ad-hoc, with no TeamIdentifier.
- Confirmed previous local config and preferences files still exist in the original sandbox container; they were not modified or migrated. The new identity uses its own preferences and folder permission. Migration/import instructions are in `macos/README.md`.
- No DMG, notarization, GitHub publication, commit or push was performed by this identity-only change. Core tests and native UI launch were not repeated; no processing or UI behavior was changed.
# Developer ID distribution preparation — 2026-09-17

- Confirmed local `Developer ID Application: Selim Erdem Camlioglu (P3M6R3G2A6)` identity with Keychain access. Restricted tool execution could not see identities and could not validate Apple's certificate chain; the same checks with host Keychain access passed.
- `swift test --package-path macos`: 12 XCTest tests passed, including the provided real export comparison.
- `SIGNING_IDENTITY=<verified certificate SHA-1> bash scripts/build-macos.sh release`: PASS. Bundle ID `com.erdemdev.texterifyrenamer`, arm64, TeamIdentifier `P3M6R3G2A6`, Hardened Runtime, Developer ID/Apple certificate chain, secure timestamp 2026-09-17 10:07:54. Strict code signature verification passed.
- Added `scripts/notarize-macos.sh`: requires Developer ID, expected team, runtime and timestamp; submits a staged copy, requires Accepted, staples the app, assesses Gatekeeper, creates/re-extracts/verifies a ZIP and writes SHA256SUMS before creating the release directory. No GitHub publication.
- Shell syntax: PASS. Missing profile fails immediately; incorrect team fails before submission. `git diff --check`: PASS.
- `notarytool history --keychain-profile texterify-renamer`: no Keychain password item found. User must save credentials locally using the documented secure prompt.
- NOT_RUN: Apple submission, stapling, notarized ZIP round trip, Gatekeeper acceptance, clean browser-download installation, and GitHub publication. The signed `.app` is not yet a notarized distribution artifact. Python release automation still needs event scoping before publishing a macOS Release.

## Notarized ZIP — 2026-09-17

This section supersedes the notarization NOT_RUN items immediately above. The user completed local Keychain credential setup; no password was supplied in chat or stored in the repository.

- `NOTARY_PROFILE=texterify-renamer TEAM_ID=P3M6R3G2A6 bash scripts/notarize-macos.sh`: PASS with host Keychain/network access.
- Apple submission `5c7782cc-5a15-4aff-ba4c-658922c88939`: **Accepted**. Response retained at `dist/notarization/Texterify-Renamer-1.0.0-arm64.S1AOzq/submission.json`.
- Staple and ticket validation: PASS. Deep/strict code signature verification: PASS. Gatekeeper: `accepted`, `source=Notarized Developer ID`.
- Final ZIP extraction: signature and stapled ticket validation PASS. SHA-256 verification PASS.
- Artifact: `dist/releases/Texterify-Renamer-1.0.0-arm64/Texterify-Renamer-1.0.0-arm64.zip` (approximately 756 KiB), accompanied by `SHA256SUMS.txt`.
- SHA-256: `2f781c1427db2bc1b2525fac8af255d79734712600a917d0ae3ad478b81e121b`.
- The ticket is attached to the staged app inside the release ZIP. The original build at `dist/Texterify Renamer.app` was not replaced or stapled; distribute the verified release ZIP.
- NOT_RUN: browser-download installation on a clean second Mac and runtime behavior under this Developer ID signature. GitHub publication, commit and push were not performed. The existing Python release workflow still needs event scoping before macOS GitHub publication.

## Sparkle update lifecycle — 2026-09-17

- Added Sparkle 2.10.0; the update feed and update archive require Ed25519 signatures. Verification before extraction is enabled. Key generated under the app-specific account in local Keychain; private key was never exported. Outgoing network permission and Sparkle installer mach-service exceptions were added without removing the app sandbox.
- UI: Preferences shows current version, opt-in automatic checks and manual checking. App/status context menus also expose the check. Scheduled updates use a quiet panel reminder; installation is manual. Relaunch is postponed while processing or while the mappings editor is open (the postponement branch itself remains NOT_RUN in native QA).
- Build and all 12 Swift tests: PASS. Sparkle framework, Installer.xpc, Autoupdate and Updater.app were individually signed with Developer ID before signing the host app.
- Initial build 3 failed native updater startup because signed feeds also require `SUVerifyUpdateBeforeExtraction`. It was removed from release output and retained under `dist/notarization/Texterify-Renamer-1.1.0-arm64.cH8BoX/rejected-release`. Fixed build 4 is the sole 1.1.0 release candidate.
- 1.1.0 build 4 notarization: **Accepted**, submission `9797d8f9-d5e0-4a62-a3c6-49a8d5f617b5`. App ticket validation, deep/strict signatures, Gatekeeper and final ZIP round trip: PASS.
- Native integration test used a separate signed copy in `dist/update-test/installed/` with version 1.0.1/build 2 and a loopback-only test feed. The production artifact was unchanged. UI showed 1.1.0 available, downloaded and extracted the final ZIP, then **Yükle ve Yeniden Başlat** installed it. The app relaunched as 1.1.0/build 4; Preferences visibly showed v1.1.0 and an enabled update button with no startup error.
- Independently verified all installed bundle file bytes and symlink targets match the final release ZIP's extracted app. Signature and stapled ticket remained valid. `/Applications/Texterify Renamer.app` was not replaced by this test.
- Crypto failure tests: genuine signed feed and ZIP verified; tampered copies of each were rejected by Sparkle `sign_update --verify`.
- Release manifest checks: PASS for final ZIP; rejected Python-asset URL, wrong build number, wrong byte count, missing archive signature, beta channel, and non-increasing build. Shell syntax and `git diff --check`: PASS.
- Final ZIP: `dist/releases/Texterify-Renamer-1.1.0-arm64/Texterify-Renamer-1.1.0-arm64.zip`; SHA-256 `f8ef53637bb63588dc38edbd65ca77c3805575ab9cb87f730193be81bc5f9e50`. The same directory contains `SHA256SUMS.txt` and signed production `appcast.xml`.
- Public repository confirmed: `ecamlioglu/texterify-language-processor`. Its existing Latest is Python v2.1.0. Added macOS-release exclusions to the Python CI workflow and a separate `macos-updates` feed design. Publication script uploads/checks the version ZIP before updating the stable feed and does not change Python's Latest designation.
- NOT_RUN: GitHub publication, public-feed update check, fresh second-Mac browser download, background check reminder/setting persistence and postponement branches, remote GitHub Actions. No commit, tag or push performed. The updater is verified against the local signed feed; its production GitHub feed URL is not yet published. The original 1.0.0 build needs a one-time manual upgrade to an updater-enabled release.

## Public GitHub release — 2026-09-17

This section supersedes the unpublished-release status above.

- Published stable release [macos-v1.1.0](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0), version 1.1.0/build 4, at source commit `7c86c332a1361f230d422cd423b61b20a5105b9c`. Python's Latest remains `v2.1.0`.
- PASS: final ZIP checksum, extracted Developer ID signature, stapled notarization ticket and Gatekeeper assessment rechecked before publication.
- PASS: anonymously downloaded public GitHub ZIP matches the notarized candidate byte-for-byte; SHA-256 `f8ef53637bb63588dc38edbd65ca77c3805575ab9cb87f730193be81bc5f9e50`.
- PASS: public `macos-updates/appcast.xml` matches the prepared feed byte-for-byte and its Sparkle signature verifies. The earlier HTTP 404 is resolved.
- Installed `/Applications/Texterify Renamer.app` reports 1.1.0/build 4 and uses this production feed URL. Native live-feed UI verification is pending because the Mac was locked during the publication check.
- Python CI exposed a Windows fixture-decoding failure; `7c86c33` explicitly reads `expected.json` as UTF-8. All 22 Python tests pass locally after that fix; its new remote run is pending.
- Remote CI is not fully passing: macOS run `35199429547` stopped at the SDK preflight because its runner has Xcode 26.6/Swift 6.3.3, while this app requires Xcode 27/Swift 6.4/macOS SDK 27. Python run `35199429505` also failed Safety's environment scan, reporting vulnerabilities in installed tooling packages; the Python application's requirements remain standard-library-only. Neither check was disabled to publish the independently verified local macOS artifact.
- Native source is unchanged since the notarized candidate was built. Committed shared JSON resources normalize CRLF to LF; their contents are semantically unchanged from the candidate. No claim of a reproducible byte-identical rebuild is made.
- A fresh second-Mac installation and the remaining native interaction checks above are still NOT_RUN.

## CI recovery — 2026-09-17

This section supersedes the remote CI failures above. Fix commit: `8062a25fadb4e22bdd69418f3facb9c49c20f8b4`.

- PASS: [Python CI/CD run 35206399966](https://github.com/ecamlioglu/texterify-language-processor/actions/runs/35206399966). All ten OS/Python test combinations, formatting/lint, documentation, Bandit, application dependency audit, performance, integration and distribution packaging passed. Existing Python `v2.1.0` was detected and left unchanged.
- The security job now runs on Python 3.12 and uses `pip-audit -r requirements.txt`; it audits declared application dependencies instead of Safety's own installed environment. The application currently has no third-party Python runtime dependencies. Bandit source scanning remains enforced, and both JSON reports are retained as CI artifacts.
- PASS: [macOS run 35206399963](https://github.com/ecamlioglu/texterify-language-processor/actions/runs/35206399963). The explicit `xcode-27` GitHub runner reports Xcode 27.0 and Swift 6.4. Toolchain/config/script checks, Swift tests, release build, strict ad-hoc signature validation, ZIP packaging and artifact upload all passed.
- Swift CI: 12 discovered tests, 11 passed, 1 expected skip, 0 failures. The skipped test requires the user's untracked local real-world ZIPs; the committed shared Python/Swift fixture runs in CI. The real-world test previously passed locally.
- CI signing remains ad-hoc for development artifacts. The public 1.1.0/build 4 Developer ID/notarized release and signed update feed are unchanged by these workflow-only fixes.
- Native public-feed UI verification remains blocked by the locked Mac. No claim of a successful native live update check is made; public feed/ZIP download and cryptographic verification have passed as recorded above.

## Native public-feed check — 2026-09-17

- PASS: after the Mac was unlocked, opened the user's installed `/Applications/Texterify Renamer.app`, navigated to **Tercihler → Güncellemeleri denetle…**, and observed the native Sparkle alert: **“Uygulama güncel! Texterify Renamer 1.1.0, kullanılabilir en yeni sürümdür.”** Both accessibility text and the screenshot confirmed the result.
- Rechecked the installed app's `SUFeedURL`: it points to the public GitHub `macos-updates/appcast.xml`. The earlier live-feed error no longer reproduces; the locked-screen blocker above is resolved.
- This proves a successful manual check against the production feed. It does not add a new upgrade/relaunch test: the installed app is already 1.1.0. The earlier signed local-feed installation test and remaining second-Mac/background-check limitations still apply.
