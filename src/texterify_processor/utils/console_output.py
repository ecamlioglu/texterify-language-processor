"""Utility for console output formatting."""

from pathlib import Path
from typing import List

from ..models.result import ProcessingResult


class ConsoleOutput:
    """Utility class for formatted console output."""

    @staticmethod
    def print_header(version_string: str):
        """Print application header."""
        print(f"🚀 {version_string}")

    @staticmethod
    def print_input_info(file_path: Path, languages: List[str]):
        """Print input file information."""
        print(f"📁 Input: {file_path.name}")
        if languages:
            language_list = ", ".join(languages)
            print(f"🌐 Languages configured: {language_list}")
        else:
            print("⚠️  No language mappings configured!")

    @staticmethod
    def print_extraction_start():
        """Print extraction start message."""
        print("📦 Extracting archive...")

    @staticmethod
    def print_result(result: ProcessingResult):
        """Print processing result."""
        if result.success:
            ConsoleOutput._print_success_result(result)
        else:
            ConsoleOutput._print_error_result(result)

    @staticmethod
    def _print_success_result(result: ProcessingResult):
        """Print successful processing result."""
        print(f"\n✅ Success! Processed {result.processed_files_count} files")

        if result.output_file:
            print(f"📦 Output: {result.output_file.name}")
            print(f"📍 Location: {result.output_file.parent}")

        if result.used_counter and result.counter_value:
            print(f"🔢 Counter: {result.counter_value}")

    @staticmethod
    def _print_error_result(result: ProcessingResult):
        """Print error result."""
        if result.error_message:
            print(f"❌ Error: {result.error_message}")
        else:
            print("❌ Processing failed")

    @staticmethod
    def print_no_language_files_warning(configured_languages: List[str]):
        """Print warning when no language files are found."""
        print("⚠️  Warning: No configured language files found in the archive!")
        if configured_languages:
            lang_list = ", ".join(configured_languages)
            print(f"💡 Make sure your zip contains files named: {lang_list}")
        print("💡 Check your configuration file: config/language_mappings.json")

    @staticmethod
    def print_completion_message(success: bool):
        """Print final completion message."""
        if success:
            print("\n🎉 Processing completed successfully!")
        else:
            print("\n💥 Processing failed!")

    @staticmethod
    def print_error(message: str):
        """Print error message."""
        print(f"❌ Error: {message}")

    @staticmethod
    def print_warning(message: str):
        """Print warning message."""
        print(f"⚠️  Warning: {message}")

    @staticmethod
    def print_info(message: str):
        """Print info message."""
        print(f"📋 Info: {message}")

    @staticmethod
    def print_renamed_file(original_name: str, new_name: str):
        """Print file rename operation."""
        print(f"✓ Renamed: {original_name} → {new_name}")
