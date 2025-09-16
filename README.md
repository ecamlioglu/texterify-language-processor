# 🌐 Texterify Language Processor

[![Python](https://img.shields.io/badge/Python-3.7%2B-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/Version-2.1.0-orange.svg)](version.py)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/ecamlioglu/texterify-language-processor/ci.yml?branch=main)](https://github.com/ecamlioglu/texterify-language-processor/actions)
[![Tests](https://img.shields.io/badge/Tests-Comprehensive-brightgreen.svg)](tests/)

A professional-grade command-line tool for processing **Texterify** language export files. Features configurable language mappings, interactive conflict resolution, and automated deployment workflows.

## ✨ Features

- 🔧 **Configurable Language Mappings**: External JSON configuration for any language combinations
- 📅 **Flexible Output Formats**: Customizable date formats and filename patterns
- 🔄 **Interactive Conflict Resolution**: Smart handling of existing files with user choice
- 🛡️ **Robust Error Handling**: Comprehensive validation and clear error messages
- 🎨 **Beautiful CLI Interface**: Clean command-line experience with progress indicators
- 🔧 **Cross-Platform**: Works seamlessly on Windows, macOS, and Linux
- 📦 **Zero Dependencies**: Uses only Python standard library
- 🚀 **Multiple Execution Options**: Python script, shell scripts, and batch files
- 🧪 **Comprehensive Testing**: Full test suite with CI/CD integration
- 📋 **Professional Documentation**: Complete examples and usage guides

## 🚀 Quick Start

### Prerequisites
- Python 3.7 or higher
- No additional dependencies required!

### Installation

```bash
# Clone the repository
git clone https://github.com/ecamlioglu/texterify-language-processor.git
cd texterify-language-processor

# Make scripts executable (Linux/macOS)
chmod +x scripts/*.sh
```

### Basic Usage

```bash
# Simple processing (uses default configuration)
python src/texterify_processor.py "your_export.zip"

# With custom configuration
python src/texterify_processor.py "your_export.zip" --config "custom_mappings.json"

# Try the included example
python src/texterify_processor.py examples/sample_texterify_export.zip
```

## 💻 Usage Examples

### Command Line Interface

```bash
# Basic processing with default config
python src/texterify_processor.py "texterify_export.zip"

# Custom configuration file
python src/texterify_processor.py "export.zip" --config "config/custom.json"

# Process the included example
python src/texterify_processor.py examples/sample_texterify_export.zip

# Full path support
python src/texterify_processor.py "C:\Downloads\my_export.zip"
```

### Shell Scripts (Recommended)

**Windows PowerShell:**
```powershell
.\scripts\texterify-processor.ps1 "your_export.zip"
```

**Linux/macOS:**
```bash
./scripts/texterify-processor.sh "your_export.zip"
```

**Windows Batch:**
```cmd
scripts\texterify-processor.bat "your_export.zip"
```

## 📋 What It Does

1. **📦 Extracts** your Texterify zip export safely
2. **🔍 Identifies** configured language files from your JSON config
3. **✏️ Renames** them according to your mapping:
   - Default: `en.*` → `24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json`
   - Default: `tr.*` → `26c7ace9-13fc-43b8-9988-2384fe670d03.json`
   - Custom: any language → any target filename
4. **📅 Creates** customizable output archives with date formatting
5. **🔄 Handles** conflicts with interactive user choice (overwrite/counter/cancel)
6. **💾 Preserves** all other files in original structure

## 📁 Project Structure

```
texterify-language-processor/
├── src/
│   └── texterify_processor.py      # Main processing engine
├── config/
│   └── language_mappings.json      # Default language configuration
├── scripts/
│   ├── texterify-processor.sh      # Unix/Linux/macOS shell script
│   ├── texterify-processor.ps1     # Windows PowerShell script
│   └── texterify-processor.bat     # Windows batch file
├── tests/
│   ├── test_processor.py           # Unit tests
│   ├── test_integration.py         # Integration tests
│   └── run_tests.py                # Test runner
├── examples/
│   ├── sample_texterify_export.zip # Real example input
│   ├── custom_config.json          # Configuration example
│   └── README.md                   # Examples documentation
├── docs/
│   └── USAGE.md                    # Detailed usage guide
├── .github/
│   ├── workflows/ci.yml            # GitHub Actions CI/CD
│   └── ISSUE_TEMPLATE/             # Issue templates
├── version.py                      # Centralized version management
├── get_version.py                  # Version extraction utility
├── .gitignore                      # Git ignore rules
├── LICENSE                         # MIT License
├── requirements.txt                # Dependencies info
└── README.md                       # This file
```

## 🎯 Output Formats

### Standard Mode
```
Input:  texterify_export.zip
Output: lang_files_16_09.zip
```

### Counter Mode
```
Input:  texterify_export.zip
Output: lang_files_16_09_1.zip  (first export of the day)

Input:  another_export.zip  
Output: lang_files_16_09_2.zip  (second export of the day)
```

### Multiple Exports Timeline
```
09:00 AM → lang_files_16_09_1.zip
11:30 AM → lang_files_16_09_2.zip  
02:15 PM → lang_files_16_09_3.zip
05:45 PM → lang_files_16_09_4.zip
```

## 🔧 Command Line Options

```
usage: texterify_processor.py [-h] [--counter [COUNTER]] [--version] zip_file

positional arguments:
  zip_file              Path to the Texterify zip export file

optional arguments:
  -h, --help            Show help message and exit
  --counter [COUNTER], -c [COUNTER]
                        Enable counter mode. Optionally specify value
  --version             Show program version
```

### Counter Options
- `--counter` or `-c`: Auto-detect next counter for today
- `--counter 5`: Use specific counter value (5)
- No counter: Standard mode (overwrites existing file)

## 📊 Example Output

```
🚀 Texterify Language Processor v2.0.0
📁 Input: my_texterify_export.zip
📦 Extracting archive...
✓ Renamed: en.json → 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
✓ Renamed: tr.json → 26c7ace9-13fc-43b8-9988-2384fe670d03.json
✅ Success! Processed 2 files
📦 Output: lang_files_16_09_3.zip
📍 Location: C:\Users\Developer\Desktop
🔢 Counter: 3

🎉 Processing completed successfully!
```

## 🛠️ Development

### Running Tests
```bash
python -m pytest tests/
```

### Code Style
```bash
# Format code
black src/ scripts/

# Lint code  
flake8 src/
```

## 🔄 Integration Examples

### CI/CD Pipeline (GitHub Actions)
```yaml
- name: Process Language Files
  run: |
    python src/texterify_processor.py "exports/languages.zip" --counter
```

### Build Script Integration
```bash
#!/bin/bash
# Download latest Texterify export
curl -o "latest_export.zip" "$TEXTERIFY_EXPORT_URL"

# Process with counter
python texterify_processor.py "latest_export.zip" --counter

# Deploy processed files
aws s3 cp lang_files_*.zip s3://my-app-bucket/languages/
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 **Documentation**: Check the [docs/](docs/) directory
- 🐛 **Bug Reports**: [Open an issue](https://github.com/ecamlioglu/texterify-language-processor/issues)
- 💡 **Feature Requests**: [Open an issue](https://github.com/ecamlioglu/texterify-language-processor/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/ecamlioglu/texterify-language-processor/discussions)

## 🏆 Why Choose This Tool?

- ✅ **Production Ready**: Used in enterprise environments
- ✅ **Well Tested**: Comprehensive test suite
- ✅ **Cross Platform**: Works everywhere Python runs
- ✅ **Zero Dependencies**: No external packages required
- ✅ **Professional**: Clean code, proper error handling
- ✅ **Flexible**: Multiple execution methods
- ✅ **Maintained**: Regular updates and bug fixes

## 🎖️ Acknowledgments

- Built for the **Texterify** localization platform
- Inspired by modern DevOps practices
- Designed for developer productivity

---

<div align="center">

**⭐ Star this repository if it helped you! ⭐**

Made with ❤️ for the developer community

</div>
