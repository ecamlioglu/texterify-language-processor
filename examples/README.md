# Try a sample export

[Mac app wiki](../docs/wiki/README.md) · [Legacy Python](../docs/wiki/Legacy-Python.md)

## In Texterify Renamer

1. Download or locate [sample_texterify_export.zip](sample_texterify_export.zip).
2. Open the menu bar panel, choose **Dosya seç**, and select it.
3. Review the English and Turkish renames.
4. Choose **ZIP’i indir** and save to a folder.

The sample includes `en.json`, `tr.json`, metadata and additional files. Only mapped filenames change; translation contents and unmatched files remain intact.

## Try custom filenames

Import [custom_config.json](custom_config.json) using **JSON içe aktar…** in the mappings editor, review it, and save. It maps `en` to `english_translations.json` and `tr` to `turkish_translations.json`.

With this config, an export processed on 17 September 2026 is named `my_app_languages_20260917.zip`. Existing names receive a counter as needed.

Export your current config first if you want to switch back later. The app keeps one active configuration.

## With legacy Python

From a repository checkout:

```sh
python src/texterify_processor.py examples/sample_texterify_export.zip
python src/texterify_processor.py examples/sample_texterify_export.zip --config examples/custom_config.json
```

The CLI may ask how to handle an existing output. For unattended runs, use [process_archive](../docs/PYTHON_LIBRARY.md).
