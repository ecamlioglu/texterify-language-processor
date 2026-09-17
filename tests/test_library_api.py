"""Checks the reusable, non-interactive API and both supported CLI entry points."""

import contextlib
import io
import subprocess
import unittest
import zipfile
from unittest.mock import patch

import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from texterify_processor import process_archive  # noqa: E402


class TestLibraryAPI(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.folder = Path(self.temporary.name)
        self.source = self.folder / "input.zip"
        with zipfile.ZipFile(self.source, "w") as archive:
            archive.writestr("en.json", '{"message":"Hello"}')
            archive.writestr("tr.json", '{"message":"Merhaba"}')

    def tearDown(self):
        self.temporary.cleanup()

    def test_library_is_quiet_noninteractive_and_preserves_existing_outputs(self):
        output = io.StringIO()
        original = self.source.read_bytes()
        with patch(
            "builtins.input", side_effect=AssertionError("Library must not read stdin")
        ), contextlib.redirect_stdout(output):
            first = process_archive(self.source)
            second = process_archive(self.source)
            cancelled = process_archive(self.source, on_conflict="cancel")
        self.assertTrue(first.success, first.error_message)
        self.assertTrue(second.success, second.error_message)
        self.assertNotEqual(first.output_file, second.output_file)
        self.assertFalse(cancelled.success)
        self.assertEqual(output.getvalue(), "")
        self.assertEqual(self.source.read_bytes(), original)

    def test_output_directory_and_strict_configuration(self):
        output = self.folder / "output"
        output.mkdir()
        result = process_archive(self.source, output_dir=output)
        self.assertTrue(result.success, result.error_message)
        self.assertEqual(result.output_file.parent, output.resolve())
        with self.assertRaises(FileNotFoundError):
            process_archive(self.source, self.folder / "missing.json")
        with self.assertRaises(ValueError):
            process_archive(self.source, on_conflict="overwrite")

    def test_both_scripts_process_real_files(self):
        root = Path(__file__).resolve().parents[1]
        for script in ["main.py", "texterify_processor.py"]:
            with self.subTest(script=script):
                result = subprocess.run(
                    [sys.executable, str(root / "src" / script), str(self.source)],
                    input="2\n",
                    text=True,
                    capture_output=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_shared_contract_fixture(self):
        fixture = Path(__file__).parent / "fixtures"
        result = process_archive(
            fixture / "export.zip", fixture / "config.json", output_dir=self.folder
        )
        self.assertTrue(result.success, result.error_message)
        expected = json.loads((fixture / "expected.json").read_text())
        with zipfile.ZipFile(result.output_file) as archive:
            actual = {
                name: archive.read(name).decode("utf-8") for name in archive.namelist()
            }
        self.assertEqual(actual, expected)
