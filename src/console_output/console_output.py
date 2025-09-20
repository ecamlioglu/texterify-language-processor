"""Utility for console output formatting."""

import sys
from pathlib import Path
from typing import Any, List


class ConsoleOutput:
    """Utility class for formatted console output."""

    @staticmethod
    def _supports_unicode():
        """Check if the current environment supports Unicode emojis."""
        try:
            # Test if we can encode a simple emoji
            "🚀".encode(sys.stdout.encoding or "utf-8")
            return True
        except (UnicodeEncodeError, UnicodeError):
            return False

    @staticmethod
    def _get_symbols():
        """Get appropriate symbols based on Unicode support."""
        if ConsoleOutput._supports_unicode():
            return {
                "rocket": "🚀",
                "folder": "📁",
                "globe": "🌐",
                "warning": "⚠️ ",
                "package": "📦",
                "check": "✓",
                "info": "📋",
                "lightbulb": "💡",
                "note": "📝",
            }
        else:
            return {
                "rocket": "[INFO]",
                "folder": "[FILE]",
                "globe": "[LANG]",
                "warning": "[WARN]",
                "package": "[ARCH]",
                "check": "[OK]",
                "info": "[INFO]",
                "lightbulb": "[TIP]",
                "note": "[NOTE]",
            }

    @staticmethod
    def print_header(version_string: str):
        """Print application header."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['rocket']} {version_string}")

    @staticmethod
    def print_input_info(file_path: Path, languages: List[str]):
        """Print input file information."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['folder']} Input: {file_path.name}")
        if languages:
            language_list = ", ".join(languages)
            print(f"{symbols['globe']} Languages configured: {language_list}")
        else:
            print(f"{symbols['warning']} No language mappings configured!")

    @staticmethod
    def print_extraction_start():
        """Print extraction start message."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['package']} Extracting archive...")

    @staticmethod
    def print_result(result: Any):
        """Print processing result."""
        if result.success:
            ConsoleOutput._print_success_result(result)
        else:
            ConsoleOutput._print_error_result(result)

    @staticmethod
    def _print_success_result(result: Any):
        """Print successful processing result."""
        symbols = ConsoleOutput._get_symbols()
        print(
            f"\n{symbols['check']} Success! Processed "
            f"{result.processed_files_count} files"
        )

        if result.output_file:
            print(f"{symbols['package']} Output: {result.output_file.name}")
            print(f"{symbols['folder']} Location: {result.output_file.parent}")

        if result.used_counter and result.counter_value:
            print(f"{symbols['info']} Counter: {result.counter_value}")

    @staticmethod
    def _print_error_result(result: Any):
        """Print error result."""
        symbols = ConsoleOutput._get_symbols()
        if result.error_message:
            print(f"{symbols['warning']} Error: {result.error_message}")
        else:
            print(f"{symbols['warning']} Processing failed")

    @staticmethod
    def print_no_language_files_warning(configured_languages: List[str]):
        """Print warning when no language files are found."""
        symbols = ConsoleOutput._get_symbols()
        print(
            f"{symbols['warning']} Warning: No configured language files "
            f"found in the archive!"
        )
        if configured_languages:
            lang_list = ", ".join(configured_languages)
            print(
                f"{symbols['lightbulb']} Make sure your zip contains files "
                f"named: {lang_list}"
            )
        print(
            f"{symbols['lightbulb']} Check your configuration file: "
            f"config/language_mappings.json"
        )

    @staticmethod
    def print_completion_message(success: bool):
        """Print final completion message."""
        symbols = ConsoleOutput._get_symbols()
        if success:
            print(f"\n{symbols['check']} Processing completed successfully!")
        else:
            print(f"\n{symbols['warning']} Processing failed!")

    @staticmethod
    def print_error(message: str):
        """Print error message."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['warning']} Error: {message}")

    @staticmethod
    def print_warning(message: str):
        """Print warning message."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['warning']} Warning: {message}")

    @staticmethod
    def print_info(message: str):
        """Print info message."""
        symbols = ConsoleOutput._get_symbols()
        print(f"{symbols['info']} Info: {message}")

    @staticmethod
    def print_renamed_file(original_name: str, new_name: str):
        """Print file rename operation."""
        symbols = ConsoleOutput._get_symbols()
        arrow = "→" if ConsoleOutput._supports_unicode() else "->"
        print(f"{symbols['check']} Renamed: {original_name} {arrow} {new_name}")
