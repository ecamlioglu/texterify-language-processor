# 🤝 Contributing to Texterify Language Processor

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Python 3.7 or higher
- Git
- Basic knowledge of Python and JSON

### Development Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/ecamlioglu/texterify-language-processor.git
   cd texterify-language-processor
   ```
3. Run the setup script:
   ```bash
   python setup.py
   ```
4. Run tests to ensure everything works:
   ```bash
   python tests/run_tests.py
   ```

## 🎯 Ways to Contribute

### 🐛 Reporting Bugs
- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Include sample files when possible (remove sensitive data)
- Provide clear reproduction steps

### 💡 Suggesting Features
- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Explain the use case and benefits
- Consider backward compatibility

### 🔧 Code Contributions
- Follow the coding standards below
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass

## 📋 Development Guidelines

### Code Style
- Follow PEP 8 Python style guide
- Use meaningful variable and function names
- Add docstrings to all functions and classes
- Keep functions focused and concise

### Testing
- Write unit tests for new functionality
- Add integration tests for complex features
- Ensure all tests pass before submitting
- Aim for good test coverage

### Documentation
- Update README.md for user-facing changes
- Add examples for new features
- Update docstrings and comments
- Consider adding usage examples

## 🔄 Pull Request Process

### Before Submitting
1. Ensure your code follows the style guidelines
2. Run all tests and ensure they pass
3. Update documentation if needed
4. Add or update tests for your changes

### Submitting
1. Create a descriptive pull request title
2. Provide a clear description of changes
3. Reference any related issues
4. Add screenshots or examples if applicable

### Review Process
1. Maintainers will review your pull request
2. Address any requested changes
3. Once approved, your PR will be merged

## 🏗️ Project Structure

### Key Files
```
├── src/texterify_processor.py    # Main application logic
├── config/language_mappings.json # Default configuration
├── version.py                    # Version management
├── tests/                        # Test suite
├── examples/                     # Usage examples
└── docs/                         # Documentation
```

### Configuration System
- Language mappings are defined in JSON files
- Settings control processing behavior
- Version info is centralized in `version.py`

## 🧪 Running Tests

### All Tests
```bash
python tests/run_tests.py
```

### Specific Test Module
```bash
python tests/run_tests.py test_processor
```

### Manual Testing
```bash
# Test with example file
python src/texterify_processor.py examples/sample_texterify_export.zip

# Test with custom config
python src/texterify_processor.py examples/sample_texterify_export.zip --config examples/custom_config.json
```

## 📦 Adding New Features

### Language Support
To add support for new languages:
1. Update `config/language_mappings.json`
2. Add test cases in `tests/`
3. Update documentation and examples

### Output Formats
To add new output formats:
1. Modify the `output_format` settings
2. Update the filename generation logic
3. Add appropriate tests

### Processing Options
To add new processing options:
1. Update the configuration schema
2. Implement the logic in the processor
3. Add CLI arguments if needed
4. Write tests and documentation

## 🐞 Debugging

### Common Issues
- **Import errors**: Ensure you're running from the project root
- **Configuration not found**: Check file paths and permissions
- **Tests failing**: Make sure you have the latest code and dependencies

### Debug Mode
Add verbose output for debugging:
```python
print(f"Debug: Processing file {file_name}")
```

### Logging
Consider adding proper logging for complex debugging scenarios.

## 📝 Coding Examples

### Adding a New Language Mapping
```python
# In the processor
def process_language_file(self, file_path, language_code):
    """Process a language file according to configuration"""
    if language_code in self.language_mappings:
        target_name = self.language_mappings[language_code]
        # Process the file...
```

### Adding a New Configuration Option
```json
{
  "settings": {
    "new_option": {
      "enabled": true,
      "value": "example"
    }
  }
}
```

## 🔍 Code Review Checklist

### For Contributors
- [ ] Code follows PEP 8 style guide
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Changes are backward compatible
- [ ] Commit messages are descriptive

### For Reviewers
- [ ] Functionality works as described
- [ ] Code is readable and maintainable
- [ ] Tests cover the new functionality
- [ ] Documentation is accurate
- [ ] No security issues introduced

## 📞 Getting Help

### Questions?
- Check the [documentation](docs/)
- Look at [existing issues](https://github.com/ecamlioglu/texterify-language-processor/issues)
- Review the [examples](examples/)

### Discussion
- Use [GitHub Discussions](https://github.com/ecamlioglu/texterify-language-processor/discussions) for general questions
- Open [issues](https://github.com/ecamlioglu/texterify-language-processor/issues) for bugs and feature requests

## 🏆 Recognition

Contributors will be recognized in:
- The project README
- Release notes for significant contributions
- Special thanks for major features or bug fixes

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Texterify Language Processor! 🎉
