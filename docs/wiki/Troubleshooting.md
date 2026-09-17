# Troubleshooting

[Wiki home](README.md) · [Report an issue](https://github.com/ecamlioglu/texterify-language-processor/issues/new/choose)

| Problem | What to check |
| --- | --- |
| No window or Dock icon | Renamer lives in the menu bar. Click its icon. |
| App will not run | The download requires macOS 27+ and Apple Silicon. See [Installation](Installation.md). |
| Download contains code | Select the named macOS ZIP in Assets, not Source code. |
| No matching languages | Compare filenames with mapping source codes and the case-sensitivity setting. |
| Config cannot be saved/imported | Resolve the validation message. Source codes and targets must be unique; targets cannot contain paths. |
| Cannot save to a folder | Select the folder again in **Tercihler**, or use **Farklı kaydet…** with a writable folder. |
| Output already exists | Use a numbered output or another name. Existing files are preserved. |
| Update check fails | Check internet access and retry. The [macOS release page](https://github.com/ecamlioglu/texterify-language-processor/releases/tag/macos-v1.1.0) also provides manual downloads. |
| Update waits to restart | Finish processing and save/close the mappings editor. |

## Archive limits

The native app accepts a single ordinary ZIP: at most 100 MiB compressed, 500 MiB expanded, and 10,000 entries. Encrypted, multipart and ZIP64 archives are unsupported. Unsafe paths, symbolic links, conflicting entries, corruption, or a changed source after preview can cause rejection.

Export a fresh standard ZIP from Texterify and retry. The original file stays intact.

## Report a problem

Include app version, macOS version, Mac architecture, reproduction steps, and the exact error. For Python, include its version and command/API call.

A small synthetic ZIP or redacted config is helpful. Do not attach private translations, credentials, or personal data. The [validation record](../MAC_APP_VALIDATION.md) distinguishes verified behavior from remaining device and accessibility checks.
