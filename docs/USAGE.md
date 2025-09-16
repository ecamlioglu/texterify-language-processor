# 📖 Texterify Language Processor - Usage Guide

Comprehensive guide for using the Texterify Language Processor in various scenarios.

## 🚀 Quick Start

### Basic Usage
```bash
python src/texterify_processor.py "your_export.zip"
```

### With Counter (Multiple Files Per Day)
```bash
python src/texterify_processor.py "your_export.zip" --counter
```

## 📱 Platform-Specific Usage

### Windows

**PowerShell (Recommended):**
```powershell
.\scripts\texterify-processor.ps1 "export.zip"
.\scripts\texterify-processor.ps1 "export.zip" -Counter
.\scripts\texterify-processor.ps1 "export.zip" -Counter 5
```

**Command Prompt:**
```cmd
scripts\texterify-processor.bat "export.zip"
scripts\texterify-processor.bat "export.zip" --counter
scripts\texterify-processor.bat "export.zip" --counter 3
```

**Direct Python:**
```cmd
python src\texterify_processor.py "export.zip"
python src\texterify_processor.py "export.zip" --counter
```

### macOS/Linux

**Shell Script (Recommended):**
```bash
./scripts/texterify-processor.sh "export.zip"
./scripts/texterify-processor.sh "export.zip" --counter
./scripts/texterify-processor.sh "export.zip" --counter 3
```

**Direct Python:**
```bash
python3 src/texterify_processor.py "export.zip"
python3 src/texterify_processor.py "export.zip" --counter
```

## 🔢 Counter Mode Explained

The counter feature allows you to process multiple Texterify exports on the same day without overwriting previous files.

### Auto-Detection Mode
```bash
# First export of the day
python src/texterify_processor.py "export1.zip" --counter
# Output: lang_files_16_09_1.zip

# Second export of the day  
python src/texterify_processor.py "export2.zip" --counter
# Output: lang_files_16_09_2.zip

# Third export of the day
python src/texterify_processor.py "export3.zip" --counter
# Output: lang_files_16_09_3.zip
```

### Manual Counter Mode
```bash
# Specify exact counter value
python src/texterify_processor.py "export.zip" --counter 5
# Output: lang_files_16_09_5.zip
```

### Timeline Example
```
Morning Export  (09:00) → lang_files_16_09_1.zip
Hotfix Export   (11:30) → lang_files_16_09_2.zip  
Feature Export  (14:15) → lang_files_16_09_3.zip
Release Export  (17:45) → lang_files_16_09_4.zip
```

## 📂 File Structure Examples

### Input Structure
Your Texterify export should contain:
```
texterify_export.zip
├── en.json          # English translations
├── tr.json          # Turkish translations
├── metadata.json    # Other files (preserved)
└── config/
    └── settings.json
```

### Output Structure
After processing:
```
lang_files_16_09.zip  (or lang_files_16_09_1.zip with counter)
├── 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json  # Renamed en.json
├── 26c7ace9-13fc-43b8-9988-2384fe670d03.json  # Renamed tr.json
├── metadata.json                               # Preserved as-is
└── config/
    └── settings.json                           # Preserved as-is
```

## 🎯 Advanced Usage

### Batch Processing
```bash
# Process multiple files with counter
for file in exports/*.zip; do
    python src/texterify_processor.py "$file" --counter
done
```

### Integration with CI/CD
```yaml
# GitHub Actions example
- name: Process Language Files
  run: |
    python src/texterify_processor.py "latest_export.zip" --counter
    
- name: Upload to S3
  run: |
    aws s3 cp lang_files_*.zip s3://my-bucket/languages/
```

### Custom Automation Script
```bash
#!/bin/bash
# automated_processor.sh

# Download latest export
curl -o "latest_export.zip" "$TEXTERIFY_API_ENDPOINT"

# Process with counter
./scripts/texterify-processor.sh "latest_export.zip" --counter

# Deploy to production
cp lang_files_*.zip /var/www/app/public/languages/

echo "Language files updated successfully!"
```

## 🛠️ Command Line Options

### Python Script Options
```
positional arguments:
  zip_file              Path to the Texterify zip export file

optional arguments:
  -h, --help            Show help message
  --counter [N], -c [N] Enable counter mode (optionally specify value)
  --version             Show program version
```

### Shell Script Options

**Bash/PowerShell:**
- `--counter`, `-c`: Auto-detect next counter
- `--counter N`: Use specific counter value N
- `--help`, `-h`: Show help
- `--version`, `-v`: Show version

**Windows Batch:**
- `--counter`: Auto-detect counter
- `--counter N`: Use counter value N  
- `--help`: Show help
- `--version`: Show version

## 🚨 Error Handling

### Common Errors and Solutions

**"Zip file not found"**
```bash
# Check file path
ls -la "your_export.zip"
# Use absolute path if needed
python src/texterify_processor.py "/full/path/to/export.zip"
```

**"No language files found"**
```bash
# Check zip contents
unzip -l "your_export.zip"
# Ensure files are named 'en' and 'tr' (any extension)
```

**"Permission denied"**
```bash
# Check file permissions
chmod 644 "your_export.zip"
# Run with appropriate permissions
sudo python src/texterify_processor.py "export.zip"
```

**"Python not found"**
```bash
# Install Python 3.7+
# On Ubuntu/Debian:
sudo apt install python3
# On macOS:
brew install python
# On Windows: Download from python.org
```

## 📊 Output Examples

### Standard Mode
```
🚀 Texterify Language Processor v2.0.0
📁 Input: my_export.zip
📦 Extracting archive...
✓ Renamed: en.json → 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
✓ Renamed: tr.json → 26c7ace9-13fc-43b8-9988-2384fe670d03.json
✅ Success! Processed 2 files
📦 Output: lang_files_16_09.zip
📍 Location: /home/user/projects
🎉 Processing completed successfully!
```

### Counter Mode
```
🚀 Texterify Language Processor v2.0.0
📁 Input: my_export.zip
📦 Extracting archive...
✓ Renamed: en.json → 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
✓ Renamed: tr.json → 26c7ace9-13fc-43b8-9988-2384fe670d03.json
✅ Success! Processed 2 files
📦 Output: lang_files_16_09_3.zip
📍 Location: /home/user/projects
🔢 Counter: 3
🎉 Processing completed successfully!
```

## 🔗 Integration Examples

### Laravel Deployment
```php
// Deploy processed language files
$langFiles = glob('lang_files_*.zip');
$latest = end($langFiles);

$zip = new ZipArchive;
if ($zip->open($latest) === TRUE) {
    $zip->extractTo(public_path('lang'));
    $zip->close();
}
```

### Node.js Build Process
```javascript
// build.js
const { exec } = require('child_process');
const path = require('path');

exec('python src/texterify_processor.py export.zip --counter', (error, stdout) => {
    if (error) {
        console.error('Processing failed:', error);
        return;
    }
    console.log('Language files processed:', stdout);
    
    // Copy to public directory
    const glob = require('glob');
    const files = glob.sync('lang_files_*.zip');
    // ... handle deployment
});
```

### Docker Integration
```dockerfile
# Dockerfile
FROM python:3.9-slim

COPY . /app
WORKDIR /app

RUN python src/texterify_processor.py exports/languages.zip --counter

COPY lang_files_*.zip /var/www/public/languages/
```

## 💡 Tips and Best Practices

1. **Use Counter Mode in Production**: Prevents accidental overwrites
2. **Automate with Cron**: Schedule regular processing
3. **Backup Original Files**: Keep source exports safe
4. **Monitor File Sizes**: Ensure processing completed successfully
5. **Test in Development**: Validate output before production use
6. **Use Shell Scripts**: More user-friendly than direct Python calls
7. **Check Exit Codes**: Handle failures in automation scripts

## 🔍 Troubleshooting

### Debug Mode
Add verbose output to Python script:
```bash
python -v src/texterify_processor.py "export.zip" --counter
```

### Validate Zip Contents
```bash
# Check zip file integrity
unzip -t "your_export.zip"

# List contents
unzip -l "your_export.zip"
```

### Check Permissions
```bash
# Linux/macOS
ls -la "your_export.zip"
chmod 644 "your_export.zip"

# Windows
icacls "your_export.zip"
```

For more help, see the [main README](../README.md) or open an [issue](https://github.com/ecamlioglu/texterify-language-processor/issues).
