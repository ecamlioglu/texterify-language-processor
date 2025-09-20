#!/usr/bin/env python3
"""
Integration tests for Texterify Language Processor
"""

import unittest
import tempfile
import zipfile
import json
import os
import sys
import subprocess
from pathlib import Path
from unittest.mock import patch

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
from texterify_processor import ProcessorController
from test_helpers import TexterifyProcessor


class TestEndToEndProcessing(unittest.TestCase):
    """End-to-end integration tests"""

    def setUp(self):
        """Set up test environment"""
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

        # Create test zip file
        self.test_zip = self.temp_path / "integration_test.zip"
        self._create_realistic_test_zip()

        # Create test config
        self.test_config = self.temp_path / "integration_config.json"
        self._create_integration_config()

    def tearDown(self):
        """Clean up test environment"""
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _create_realistic_test_zip(self):
        """Create a realistic Texterify-like export"""
        with zipfile.ZipFile(self.test_zip, "w") as zf:
            # Language files with realistic content
            en_content = {
                "app.title": "My Application",
                "buttons.save": "Save",
                "buttons.cancel": "Cancel",
                "messages.welcome": "Welcome to our app!",
                "errors.required": "This field is required",
            }

            tr_content = {
                "app.title": "Uygulamam",
                "buttons.save": "Kaydet",
                "buttons.cancel": "İptal",
                "messages.welcome": "Uygulamamıza hoş geldiniz!",
                "errors.required": "Bu alan zorunludur",
            }

            # Add language files
            zf.writestr("en.json", json.dumps(en_content, indent=2))
            zf.writestr("tr.json", json.dumps(tr_content, indent=2, ensure_ascii=False))

            # Add metadata files that should be preserved
            zf.writestr(
                "_metadata.json",
                json.dumps(
                    {
                        "exported_at": "2025-09-16T10:30:00Z",
                        "project_id": "12345",
                        "version": "1.2.3",
                    },
                    indent=2,
                ),
            )

            # Add nested structure
            zf.writestr("assets/icons/info.txt", "Icon files go here")
            zf.writestr("docs/README.txt", "Documentation files")

    def _create_integration_config(self):
        """Create integration test configuration"""
        config = {
            "_metadata": {
                "description": "Integration test configuration",
                "version": "1.0.0",
            },
            "language_mappings": {
                "en": "24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json",
                "tr": "26c7ace9-13fc-43b8-9988-2384fe670d03.json",
            },
            "settings": {
                "case_sensitive": False,
                "preserve_extensions": False,
                "backup_original": False,
                "output_format": {
                    "date_format": "%Y%m%d",
                    "base_filename": "integration_test",
                    "extension": ".zip",
                },
            },
        }

        with open(self.test_config, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2, ensure_ascii=False)

    @patch("builtins.input", return_value="2")  # Choose "add counter"
    def test_complete_processing_flow(self, mock_input):
        """Test complete processing flow from start to finish"""
        # Initialize processor
        controller = ProcessorController(str(self.test_zip), str(self.test_config))

        # Change output directory to temp directory
        controller.output_service.output_dir = self.temp_path

        # Process the file
        result = controller.process()

        # Should succeed
        self.assertTrue(result.success)

        # Check that output file was created
        output_files = list(self.temp_path.glob("integration_test_*.zip"))
        self.assertTrue(len(output_files) > 0)

        # Verify output zip contents
        output_zip = output_files[0]
        self._verify_output_zip(output_zip)

    def _verify_output_zip(self, output_zip_path):
        """Verify the contents of the output zip file"""
        with zipfile.ZipFile(output_zip_path, "r") as zf:
            file_list = zf.namelist()

            # Check that language files were renamed
            self.assertIn("24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json", file_list)
            self.assertIn("26c7ace9-13fc-43b8-9988-2384fe670d03.json", file_list)

            # Check that original language files are gone
            self.assertNotIn("en.json", file_list)
            self.assertNotIn("tr.json", file_list)

            # Check that other files are preserved
            self.assertIn("_metadata.json", file_list)
            self.assertIn("assets/icons/info.txt", file_list)
            self.assertIn("docs/README.txt", file_list)

            # Verify content of renamed files
            en_content = zf.read("24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json")
            tr_content = zf.read("26c7ace9-13fc-43b8-9988-2384fe670d03.json")

            # Should be valid JSON
            en_data = json.loads(en_content)
            tr_data = json.loads(tr_content)

            # Verify content
            self.assertEqual(en_data["app.title"], "My Application")
            self.assertEqual(tr_data["app.title"], "Uygulamam")

    def test_multiple_file_processing(self):
        """Test processing multiple files in sequence"""
        processor = TexterifyProcessor(str(self.test_zip), str(self.test_config))
        processor.output_dir = self.temp_path

        # Mock user choices for multiple runs
        with patch(
            "builtins.input", side_effect=["2", "2", "2"]
        ):  # Always choose counter
            # Process same file multiple times
            for i in range(3):
                result = processor.process()
                self.assertTrue(result)

        # Should have output files with different counters
        output_files = list(self.temp_path.glob("integration_test_*_*.zip"))
        self.assertGreaterEqual(len(output_files), 2)  # At least 2 files with counters

        # Verify counter sequence
        counters = []
        for file in output_files:
            # Extract counter from filename like "integration_test_20250916_1.zip"
            parts = file.stem.split("_")
            if len(parts) >= 3:
                counters.append(int(parts[-1]))

        counters.sort()
        self.assertGreaterEqual(len(counters), 2)  # At least 2 different counters
        self.assertEqual(
            counters, list(range(1, len(counters) + 1))
        )  # Sequential counters


class TestCommandLineInterface(unittest.TestCase):
    """Test command-line interface"""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

        # Create test files
        self.test_zip = self.temp_path / "cli_test.zip"
        with zipfile.ZipFile(self.test_zip, "w") as zf:
            zf.writestr("en.json", '{"test": "value"}')

        self.script_path = (
            Path(__file__).parent.parent / "src" / "texterify_processor.py"
        )

    def tearDown(self):
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_version_argument(self):
        """Test --version argument"""
        result = subprocess.run(
            [sys.executable, str(self.script_path), "--version"],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("Texterify Language Processor", result.stdout)

    def test_help_argument(self):
        """Test --help argument"""
        result = subprocess.run(
            [sys.executable, str(self.script_path), "--help"],
            capture_output=True,
            text=True,
        )

        # Help should exit with 0 or 1 (argparse may vary)
        self.assertIn(result.returncode, [0, 1])
        # Check for usage and texterify in the output
        combined_output = result.stdout + result.stderr
        self.assertTrue(
            "usage:" in combined_output.lower(),
            f"Expected 'usage:' in output: {repr(combined_output)}",
        )
        self.assertTrue(
            "texterify" in combined_output.lower(),
            f"Expected 'texterify' in output: {repr(combined_output)}",
        )


class TestErrorHandling(unittest.TestCase):
    """Test error handling scenarios"""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

    def tearDown(self):
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_invalid_zip_file(self):
        """Test handling of invalid zip files"""
        # Create a non-zip file
        fake_zip = self.temp_path / "fake.zip"
        with open(fake_zip, "w") as f:
            f.write("This is not a zip file")

        processor = TexterifyProcessor(str(fake_zip))
        self.assertFalse(processor.validate_zip_file())

    def test_empty_zip_file(self):
        """Test handling of empty zip files"""
        empty_zip = self.temp_path / "empty.zip"
        with zipfile.ZipFile(empty_zip, "w") as zf:
            pass  # Create empty zip

        processor = TexterifyProcessor(str(empty_zip))
        processor.output_dir = self.temp_path

        # Should complete but with no files processed
        with patch("builtins.input", return_value="1"):  # Overwrite
            result = processor.process()
            self.assertFalse(result)  # Should fail due to no language files

    def test_missing_language_files(self):
        """Test handling when no configured language files are found"""
        zip_without_langs = self.temp_path / "no_langs.zip"
        with zipfile.ZipFile(zip_without_langs, "w") as zf:
            zf.writestr("other.json", '{"data": "value"}')
            zf.writestr("config.xml", "<config></config>")

        processor = TexterifyProcessor(str(zip_without_langs))
        processor.output_dir = self.temp_path

        with patch("builtins.input", return_value="1"):  # Overwrite
            result = processor.process()
            self.assertFalse(result)  # Should fail due to no language files


if __name__ == "__main__":
    unittest.main(verbosity=2)
