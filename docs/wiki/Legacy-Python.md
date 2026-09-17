# Legacy Python

[Wiki home](README.md) · [Mac app download](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0)

Texterify Renamer is the primary application. The original **Texterify Language Processor** remains available for terminal use, automation, and Python integrations on Windows, macOS, and Linux.

“Legacy” identifies this separate workflow; the code has not been removed. The Mac app does not require it.

| | Native macOS app | Legacy Python |
| --- | --- | --- |
| Interface | Menu bar, drag/drop, preview, editor | CLI or Python API |
| Requirements | macOS 27+, Apple Silicon | Python 3.8+ |
| Engine | Swift | Python standard library |
| Updates | Signed in-app updates | Install the desired source revision/package |
| Existing output | New name or cancel | API: counter/cancel; CLI also offers overwrite |

See the [Python installation, CLI and API reference](../PYTHON_LIBRARY.md) for copyable commands and automation examples.

Python remains **2.1.0**, independent of macOS **1.1.0**. The historical [Python v2.1.0 release](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/v2.1.0) predates the reusable API. Install current repository source for `process_archive(...)`.
