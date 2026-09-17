# Python library

The Python package and native macOS app stay in this repository. They share the JSON configuration format and contract fixture. The app has its own Swift core and does not spawn Python.

```sh
python -m pip install .
texterify-processor export.zip
python -m texterify_processor export.zip
```

Non-interactive use:

```python
from texterify_processor import process_archive

result = process_archive(
    "export.zip",
    config_path="config/language_mappings.json",  # optional
    output_dir="exports",                      # existing folder; optional
    on_conflict="counter",                     # or "cancel"
)
if not result.success:
    raise RuntimeError(result.error_message)
print(result.output_file)
```

`process_archive` never reads stdin or prints. By default it adds a counter when the output name already exists. `cancel` returns an unsuccessful `ProcessingResult` on conflict. Invalid config loading raises an exception instead of silently choosing defaults. The lower-level `ProcessorController`, `ProcessingConfig` and `ProcessingResult` imports remain available. Legacy scripts `src/main.py` and `src/texterify_processor.py` delegate to the package CLI.

This API wraps the existing Python processor; it does not introduce all of the Swift app's stricter archive preflight checks. Use trusted Texterify exports. The CLI retains its existing interactive config-loading and overwrite behavior for compatibility.

The version's source of truth is `src/texterify_processor/version.py`; root `version.py` is a compatibility import. Wheel/sdist builds include the repository's default config through `setup.py`/`MANIFEST.in`.

```sh
python tests/run_tests.py
python -m pip wheel . --no-deps -w dist
```
