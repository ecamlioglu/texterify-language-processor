# Contributing to Texterify Renamer

The primary product is the native macOS menu bar app. The legacy Python CLI/library remains a separate, usable part of the same repository.

## Find the relevant area

| Area | Source |
| --- | --- |
| Native interface and updater | `macos/Sources/TexterifyRenamer/` |
| Swift processing | `macos/Sources/RenamerCore/` |
| Legacy Python | `src/texterify_processor/` |
| Shared config | `config/language_mappings.json` |
| User documentation | `docs/wiki/` |

## Build the Mac app

Use macOS 27+, Xcode 27 and Swift 6.4. A signing certificate is not needed for local development.

```sh
swift test --package-path macos
bash scripts/build-macos.sh release
open 'dist/Texterify Renamer.app'
```

Quit the development app before rebuilding its bundle. Local builds are ad-hoc signed. Public distribution uses the separate [signing/release workflow](macos/README.md); CI artifacts are not notarized public installers.

Keep routine actions in the menu bar panel. Use a separate window when editing needs room. Follow native Liquid Glass, accessibility and appearance behavior. Keep labels understandable without exposing implementation details.

## Work on Python

Use Python 3.8+ in a virtual environment:

```sh
python -m pip install -e .
python tests/run_tests.py
python -m pip install black isort flake8
black --check src/ tests/
isort --check-only src/ tests/
flake8 src/ tests/ --max-line-length=88 --extend-ignore=E203,W503
```

Preserve the CLI entry points and quiet `process_archive` API. Package versioning is independent of the app. See the [Python reference](docs/PYTHON_LIBRARY.md).

## Shared behavior and validation

When changing bundled defaults, keep `config/language_mappings.json` and `macos/Sources/RenamerCore/Resources/default-config.json` byte-identical. Both engines use `tests/fixtures/` for their shared mapping contract.

Run checks relevant to the change. Processing changes should cover affected archive behavior; visual changes need native interaction checks. The optional real-export Swift test skips in CI when local samples are absent.

## Issues and pull requests

Describe the problem, expected result, and reproduction steps. Include app/macOS or Python versions as appropriate. Use synthetic samples or redacted configs.

For pull requests, explain the resulting behavior, checks performed and remaining limits. Include screenshots for UI changes. Keep unrelated files and generated artifacts out of the change.

The [wiki](docs/wiki/README.md) is the current user guide. The [original plan](docs/MAC_APP_PLAN.md) and [validation record](docs/MAC_APP_VALIDATION.md) are historical engineering records.

Contributions use the repository's [MIT License](LICENSE).
