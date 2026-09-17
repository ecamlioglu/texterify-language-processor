# Daily workflow

[Wiki home](README.md) · [Configuration](Configuration.md)

## Convert an export

1. Click the menu bar icon and choose **Dosya seç**, or drop one ZIP onto the panel or menu bar icon.
2. Review the proposed changes. Expand the change list to inspect original and target names.
3. Choose **ZIP’i indir** to save. The first save asks for a destination folder.
4. Select **Finder’da göster** to reveal the archive. Use **Yeni dosya** for another export.

The app renames files inside the archive. It does not translate strings or change translation contents. Unmatched files are preserved, including folder paths. Nested matching files are renamed in their existing folders.

The original ZIP is never changed. Existing outputs are not overwritten: the default is a new numbered filename. For example, `lang_files_17_09.zip` can become `lang_files_17_09_1.zip`.

## Save somewhere else

Use **Farklı kaydet…** for a different destination. Under **Tercihler**, set the normal output folder or enable **Her indirmede kayıt yeri sor** to choose each time.

**Aynı dosya adı varsa bana sor** lets you choose how to handle an existing name. The Mac app still does not overwrite that file.

## Manage the workspace

Routine preferences stay inside the menu bar panel. The mappings editor opens as a separate window when you need room to edit. Save its changes with **Kaydet** in the toolbar.

Choose **Sistem**, **Açık**, or **Koyu** in preferences for appearance. Choose **Çıkış** from **Diğer işlemler** to quit.

Try the [sample walkthrough](../../examples/README.md), or consult [Troubleshooting](Troubleshooting.md).
