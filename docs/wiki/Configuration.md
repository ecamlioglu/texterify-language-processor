# Configuration

[Wiki home](README.md) · [Daily workflow](Usage.md)

## Edit mappings

Click the config name at the bottom of the panel, or open **Tercihler → Eşleştirmeler**. Each row maps a source language code to a target filename.

| Source | Target | Result |
| --- | --- | --- |
| `en` | `english.json` | `en.json` becomes `english.json` |
| `tr` | `turkish.json` | `tr.json` becomes `turkish.json` |

The source is the filename without its final extension. Targets can be readable names or the UUID filenames your project expects. Use plain filenames, not folder paths.

Search for a row, use **Eşleştirme ekle** to add one, and select **Kaydet**. Duplicate source codes, duplicate targets, and unsafe filenames are rejected. Enable **Büyük/küçük harf duyarlı** only when uppercase/lowercase source names must be distinct.

One configuration is active at a time. Import/export JSON to keep configurations for different projects.

## JSON import and export

The editor's actions menu contains **JSON içe aktar…** and **JSON dışa aktar…**. **JSON önizleme** shows the current configuration. Start with [examples/custom_config.json](../../examples/custom_config.json), or this minimal configuration:

```json
{
  "language_mappings": {
    "en": "english.json",
    "tr": "turkish.json"
  },
  "settings": {
    "case_sensitive": false,
    "output_format": {
      "base_filename": "my_app",
      "date_format": "%d_%m",
      "extension": ".zip"
    }
  }
}
```

Both implementations understand this shared format. The Mac app applies stricter validation. Legacy keys `preserve_extensions` and `backup_original` must be omitted or false; they do not enable extra Mac app features.

## Output names

Change the prefix and date style in **Tercihler**, then apply the change. The date is the processing date, not one parsed from the source filename.

| JSON date format | Example on 17 September 2026 |
| --- | --- |
| `%d_%m` | `my_app_17_09.zip` |
| `%Y%m%d` | `my_app_20260917.zip` |
| `%Y-%m-%d` | `my_app_2026-09-17.zip` |
| `%Y-%m-%d_%H%M` | `my_app_2026-09-17_1430.zip` |

Output uses `.zip`. Existing names receive a numeric suffix as needed.

The [bundled default](../../config/language_mappings.json) includes 11 mappings. Its target IDs come from the original workflow; replace them with your project's filenames.
