#!/usr/bin/env python3
"""
Test suite for Texterify Language Processor
"""

import json
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

# Add src to path to import the processor
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
from test_helpers import TexterifyProcessor

from texterify_processor import ProcessorController
from texterify_processor.models.config import ProcessingConfig
from texterify_processor.services.config_service import ConfigService


class TestTexterifyProcessor(unittest.TestCase):
    """Test cases for TexterifyProcessor class"""

    def setUp(self):
        """Set up test environment"""
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

        # Create test zip file with language files
        self.test_zip = self.temp_path / "test_export.zip"
        self._create_test_zip()

        # Create test config
        self.test_config = self.temp_path / "test_config.json"
        self._create_test_config()

    def tearDown(self):
        """Clean up test environment"""
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _create_test_zip(self):
        """Create a test zip file with sample language files"""
        with zipfile.ZipFile(self.test_zip, "w") as zf:
            # Add language files
            zf.writestr("en.json", '{"hello": "Hello", "world": "World"}')
            zf.writestr("tr.json", '{"hello": "Merhaba", "world": "Dünya"}')
            zf.writestr("fr.json", '{"hello": "Bonjour", "world": "Monde"}')

            # Add other files that should be preserved
            zf.writestr("metadata.json", '{"version": "1.0", "created": "2025-09-16"}')
            zf.writestr("config/settings.json", '{"theme": "dark"}')

    def _create_test_config(self):
        """Create a test configuration file"""
        config = {
            "language_mappings": {
                "en": "english_translations.json",
                "tr": "turkish_translations.json",
                "fr": "french_translations.json",
            },
            "settings": {
                "case_sensitive": False,
                "output_format": {
                    "date_format": "%Y%m%d",
                    "base_filename": "test_output",
                    "extension": ".zip",
                },
            },
        }

        with open(self.test_config, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)

    def test_processor_initialization(self):
        """Test processor initialization"""
        controller = ProcessorController(str(self.test_zip))
        self.assertEqual(controller.zip_path, Path(self.test_zip).resolve())
        self.assertIsInstance(controller.config.language_mappings, dict)

    def test_processor_with_custom_config(self):
        """Test processor with custom configuration"""
        controller = ProcessorController(str(self.test_zip), str(self.test_config))

        # Check that custom config was loaded
        expected_mappings = {
            "en": "english_translations.json",
            "tr": "turkish_translations.json",
            "fr": "french_translations.json",
        }
        self.assertEqual(controller.config.language_mappings, expected_mappings)

    def test_config_loading(self):
        """Test configuration loading"""
        processor = TexterifyProcessor(str(self.test_zip), str(self.test_config))
        config = processor.config

        self.assertIsNotNone(config.language_mappings)
        self.assertIsNotNone(config.output_format)
        self.assertEqual(config.output_format.base_filename, "test_output")

    def test_base_filename_generation(self):
        """Test base filename generation"""
        processor = TexterifyProcessor(str(self.test_zip), str(self.test_config))
        base_filename = processor.generate_base_filename()

        # Should use custom format from config
        self.assertTrue(base_filename.startswith("test_output_"))
        self.assertRegex(base_filename, r"test_output_\d{8}")

    def test_output_filename_generation(self):
        """Test output filename generation"""
        processor = TexterifyProcessor(str(self.test_zip), str(self.test_config))

        # Without counter
        filename = processor.generate_output_filename(use_counter=False)
        self.assertTrue(filename.endswith(".zip"))

        # With counter
        filename_with_counter = processor.generate_output_filename(use_counter=True)
        self.assertTrue(filename_with_counter.endswith(".zip"))
        self.assertRegex(filename_with_counter, r"test_output_\d{8}_\d+\.zip")

    def test_zip_validation(self):
        """Test zip file validation"""
        processor = TexterifyProcessor(str(self.test_zip))
        self.assertTrue(processor.validate_zip_file())

        # Test with non-existent file
        invalid_processor = TexterifyProcessor("nonexistent.zip")
        self.assertFalse(invalid_processor.validate_zip_file())

    def test_default_config_fallback(self):
        """Test fallback to default configuration"""
        # Test with non-existent config
        processor = TexterifyProcessor(str(self.test_zip), "nonexistent_config.json")

        # Should have default mappings
        self.assertIn("en", processor.language_mappings)
        self.assertIn("tr", processor.language_mappings)

    def test_case_sensitivity(self):
        """Test case sensitivity setting"""
        # Create config with case sensitivity enabled
        case_sensitive_config = self.temp_path / "case_sensitive.json"
        config = {
            "language_mappings": {"EN": "ENGLISH.json", "en": "english.json"},
            "settings": {"case_sensitive": True},
        }

        with open(case_sensitive_config, "w") as f:
            json.dump(config, f)

        processor = TexterifyProcessor(str(self.test_zip), str(case_sensitive_config))
        self.assertTrue(processor.settings.get("case_sensitive", False))


class TestVersionInfo(unittest.TestCase):
    """Test version information functionality"""

    def test_version_import(self):
        """Test that version information can be imported"""
        # Add project root to path
        project_root = Path(__file__).parent.parent
        sys.path.insert(0, str(project_root))

        from version import PROJECT_NAME, VERSION, get_version_string

        self.assertIsInstance(VERSION, str)
        self.assertIsInstance(PROJECT_NAME, str)
        self.assertIn(VERSION, get_version_string())


class TestConfigurationValidation(unittest.TestCase):
    """Test configuration file validation"""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

    def tearDown(self):
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_valid_config(self):
        """Test loading valid configuration"""
        config_file = self.temp_path / "valid_config.json"
        config = {
            "language_mappings": {"en": "english.json"},
            "settings": {"case_sensitive": False},
        }

        with open(config_file, "w") as f:
            json.dump(config, f)

        # Create a dummy zip file for testing
        zip_file = self.temp_path / "test.zip"
        with zipfile.ZipFile(zip_file, "w") as zf:
            zf.writestr("en.json", "{}")

        processor = TexterifyProcessor(str(zip_file), str(config_file))
        self.assertEqual(processor.language_mappings["en"], "english.json")

    def test_invalid_json_config(self):
        """Test handling of invalid JSON configuration"""
        config_file = self.temp_path / "invalid_config.json"

        # Write invalid JSON
        with open(config_file, "w") as f:
            f.write('{"invalid": json}')

        zip_file = self.temp_path / "test.zip"
        with zipfile.ZipFile(zip_file, "w") as zf:
            zf.writestr("en.json", "{}")

        # Should fall back to default config
        processor = TexterifyProcessor(str(zip_file), str(config_file))
        self.assertIn("en", processor.language_mappings)


def run_tests():
    """Run all tests"""
    # Discover and run tests
    loader = unittest.TestLoader()
    suite = loader.discover(".", pattern="test_*.py")

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
