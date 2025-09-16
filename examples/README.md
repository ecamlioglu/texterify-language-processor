# 📝 Examples - Texterify Language Processor

This directory contains practical examples to help you understand and use the Texterify Language Processor effectively.

## 📁 Files in this Directory

### `sample_texterify_export.zip`
A realistic example of what a Texterify export looks like, containing:
- **English translations** (`en.json`) - 12 common app strings
- **Turkish translations** (`tr.json`) - Same strings in Turkish with UTF-8 characters
- **Metadata file** (`_metadata.json`) - Export information
- **Additional files** (`assets/`, `docs/`) - Files that should be preserved

### `custom_config.json`
Example configuration file showing how to:
- Map different languages to custom filenames
- Use different output formats (date format, base filename)
- Configure case sensitivity and other settings
- Add new languages beyond the default en/tr

## 🚀 Quick Start Example

### 1. Basic Usage (Default Configuration)
```bash
# Process the sample export with default settings
python src/texterify_processor.py examples/sample_texterify_export.zip
```

**What happens:**
- Loads default configuration from `config/language_mappings.json`
- Renames `en.json` → `24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json`
- Renames `tr.json` → `26c7ace9-13fc-43b8-9988-2384fe670d03.json`
- Creates `lang_files_16_09.zip` in the same directory
- Preserves all other files unchanged

### 2. Custom Configuration
```bash
# Process with custom configuration
python src/texterify_processor.py examples/sample_texterify_export.zip --config examples/custom_config.json
```

**What happens:**
- Uses custom language mappings from `custom_config.json`
- Renames `en.json` → `english_translations.json`
- Renames `tr.json` → `turkish_translations.json`
- Creates `my_app_languages_20250916.zip` with YYYYMMDD format

### 3. Shell Script Usage
```bash
# Unix/Linux/macOS
./scripts/texterify-processor.sh examples/sample_texterify_export.zip

# Windows PowerShell
.\scripts\texterify-processor.ps1 examples\sample_texterify_export.zip

# Windows Batch
scripts\texterify-processor.bat examples\sample_texterify_export.zip
```

## 🎯 Step-by-Step Tutorial

### Step 1: Examine the Sample Export
```bash
# Look at what's in the sample export
unzip -l examples/sample_texterify_export.zip
```

You'll see:
```
Archive:  sample_texterify_export.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      318  2025-09-16 10:30   en.json
      356  2025-09-16 10:30   tr.json
      156  2025-09-16 10:30   _metadata.json
       20  2025-09-16 10:30   assets/icons/info.txt
       18  2025-09-16 10:30   docs/README.txt
---------                     -------
      868                     5 files
```

### Step 2: Process with Default Settings
```bash
python src/texterify_processor.py examples/sample_texterify_export.zip
```

**Output:**
```
📋 Loaded configuration from: language_mappings.json
🚀 Texterify Language Processor v2.1.0
📁 Input: sample_texterify_export.zip
🌐 Languages configured: en, tr
📦 Extracting archive...
✓ Renamed: en.json → 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
✓ Renamed: tr.json → 26c7ace9-13fc-43b8-9988-2384fe670d03.json

✅ Success! Processed 2 files
📦 Output: lang_files_16_09.zip
📍 Location: /path/to/examples
🎉 Processing completed successfully!
```

### Step 3: Verify the Output
```bash
# Check the processed output
unzip -l lang_files_16_09.zip
```

You'll see the language files have been renamed:
```
Archive:  lang_files_16_09.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      318  2025-09-16 10:30   24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
      356  2025-09-16 10:30   26c7ace9-13fc-43b8-9988-2384fe670d03.json
      156  2025-09-16 10:30   _metadata.json
       20  2025-09-16 10:30   assets/icons/info.txt
       18  2025-09-16 10:30   docs/README.txt
---------                     -------
      868                     5 files
```

### Step 4: Multiple Files (Counter Feature)
Run the same command again:
```bash
python src/texterify_processor.py examples/sample_texterify_export.zip
```

You'll be prompted:
```
⚠️  Output file already exists: lang_files_16_09.zip

What would you like to do?
1. Overwrite existing file
2. Add counter to create new file
3. Cancel operation

Enter your choice (1-3): 2
```

Choose option 2 to create `lang_files_16_09_2.zip`.

## 🛠️ Configuration Examples

### Example 1: Adding New Languages
Copy `custom_config.json` and add more languages:
```json
{
  "language_mappings": {
    "en": "english.json",
    "tr": "turkish.json",
    "fr": "french.json",
    "de": "german.json",
    "es": "spanish.json",
    "it": "italian.json",
    "pt": "portuguese.json"
  }
}
```

### Example 2: Custom Output Format
```json
{
  "settings": {
    "output_format": {
      "date_format": "%Y-%m-%d_%H%M",
      "base_filename": "production_release",
      "extension": ".zip"
    }
  }
}
```
This creates files like: `production_release_2025-09-16_1430.zip`

### Example 3: Case Sensitive Mode
```json
{
  "language_mappings": {
    "EN": "ENGLISH.json",
    "en": "english.json"
  },
  "settings": {
    "case_sensitive": true
  }
}
```

## 🔧 Testing the Examples

### Run the Test Suite
```bash
# Run all tests
python tests/run_tests.py

# Run specific test
python tests/run_tests.py test_processor
```

### Manual Testing
```bash
# Test with the sample file
python src/texterify_processor.py examples/sample_texterify_export.zip

# Test with custom config
python src/texterify_processor.py examples/sample_texterify_export.zip --config examples/custom_config.json

# Test version info
python src/texterify_processor.py --version
```

## 💡 Real-World Scenarios

### Scenario 1: CI/CD Pipeline
```bash
#!/bin/bash
# deploy_languages.sh

# Download latest export from Texterify
curl -o "latest_export.zip" "$TEXTERIFY_EXPORT_URL"

# Process with production config
python src/texterify_processor.py "latest_export.zip" --config "config/production.json"

# Deploy to CDN
aws s3 cp lang_files_*.zip s3://my-app-cdn/languages/
```

### Scenario 2: Development Workflow
```bash
# Quick processing during development
./scripts/texterify-processor.sh downloads/texterify_export.zip

# Copy to project public folder
cp lang_files_*.zip ../my-app/public/languages/
```

### Scenario 3: Multiple Environments
```bash
# Development environment
python src/texterify_processor.py export.zip --config config/dev.json

# Staging environment  
python src/texterify_processor.py export.zip --config config/staging.json

# Production environment
python src/texterify_processor.py export.zip --config config/production.json
```

## 🎓 Learning More

1. **Read the main README**: `../README.md` for complete documentation
2. **Check the configuration**: `../config/language_mappings.json` for default settings
3. **Run the tests**: `../tests/` for understanding the codebase
4. **Explore the source**: `../src/texterify_processor.py` for implementation details

## ❓ Common Questions

**Q: Can I add more than en/tr languages?**  
A: Yes! Edit the configuration file to add any languages you need.

**Q: Can I use different output filenames?**  
A: Yes! Customize the `output_format` settings in your configuration.

**Q: What if my export has different file names?**  
A: Update the `language_mappings` in your configuration to match your file names.

**Q: Can I automate this process?**  
A: Yes! Use the shell scripts or integrate the Python script into your build process.

---

🎉 **Start with the basic example above and customize as needed for your project!**
