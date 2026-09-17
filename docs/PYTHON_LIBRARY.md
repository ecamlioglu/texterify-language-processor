# Texterify Language Processor — legacy Python

The terminal and library companion to Texterify Renamer. Python is useful for automation and Windows/Linux users; it is not required by the Mac app.

Requires **Python 3.8+**. Core processing uses only the Python standard library.

## Install from source

```sh
git clone https://github.com/ecamlioglu/texterify-language-processor.git
cd texterify-language-processor
python -m venv .venv
```

Activate the environment:

```sh
# macOS / Linux
source .venv/bin/activate
```

```powershell
# Windows PowerShell
.venv\Scripts\Activate.ps1
```

Then install:

```sh
python -m pip install .
texterify-processor --version
```

Use `python3` or `py -3` instead of `python` if needed. For reproducible automation, check out a reviewed commit before installation.

The Python package version remains **2.1.0**. Historical GitHub Python release assets predate the library refactor; install current repository source for the API below. These instructions do not assume a public PyPI package.

## CLI

```sh
texterify-processor "export.zip"
texterify-processor "export.zip" --config "my-config.json"
python -m texterify_processor "export.zip"
```

Compatibility entry points from a checkout:

```sh
python src/texterify_processor.py "export.zip"
python src/main.py "export.zip"
```

| Argument | Meaning |
| --- | --- |
| `zip_file` | Input ZIP path |
| `--config PATH`, `-c PATH` | Custom JSON config |
| `--version` | Print Python tool version |
| `--help`, `-h` | Supported arguments |

There is no `--counter` flag in the current CLI. `-c` means config. When the output exists, the CLI offers overwrite, add a counter, or cancel. Use the API for unattended jobs.

By default output is written beside the input. Naming and mappings come from JSON configuration; `examples/custom_config.json` is a starting point.

## Non-interactive API

After installing the current source:

```python
from pathlib import Path
from texterify_processor import process_archive

output = Path("exports")
output.mkdir(exist_ok=True)

result = process_archive(
    "export.zip",
    config_path="my-config.json",  # omit to use bundled defaults
    output_dir=output,            # must already exist
    on_conflict="counter",        # or "cancel"
)
if not result.success:
    raise RuntimeError(result.error_message)
print(result.output_file)
```

`process_archive` does not print or read stdin. Its default `counter` policy preserves existing outputs with numbered names. `cancel` returns an unsuccessful result on conflict. Invalid config loading raises an exception.

For multiple exports:

```python
from pathlib import Path
from texterify_processor import process_archive

output = Path("processed")
output.mkdir(exist_ok=True)

for source in sorted(Path("incoming").glob("*.zip")):
    result = process_archive(source, output_dir=output, on_conflict="counter")
    if not result.success:
        raise RuntimeError(f"{source.name}: {result.error_message}")
    print(result.output_file)
```

## Compatibility and development

The Swift and Python implementations share JSON configuration and a contract fixture, but use separate engines. The API wraps the legacy processor and does not provide all of the Swift app's stricter archive checks. Use trusted Texterify exports.

The CLI retains historical config fallback and interactive overwrite behavior. The API uses strict config loading and offers counter/cancel only. Lower-level `ProcessorController`, `ProcessingConfig`, and `ProcessingResult` imports remain available.

Python versioning comes from `src/texterify_processor/version.py`; root `version.py` is a compatibility import. Wheels and source distributions include the default config.

```sh
python tests/run_tests.py
python -m pip wheel . --no-deps -w dist
```

[Repository wiki](https://github.com/ecamlioglu/texterify-language-processor/blob/main/docs/wiki/README.md) · [Contributing](https://github.com/ecamlioglu/texterify-language-processor/blob/main/CONTRIBUTING.md)
