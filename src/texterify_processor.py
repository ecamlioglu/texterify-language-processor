#!/usr/bin/env python3
"""
Texterify Language Processor - Legacy Entry Point
=================================================

DEPRECATED: This file maintains backward compatibility with the old interface.
For new development, use the refactored architecture in src/main.py

Author: Texterify Language Processor Team
License: MIT
"""

import argparse
import sys
from pathlib import Path

# Import version information
sys.path.append(str(Path(__file__).parent.parent))
# Import the new architecture
from texterify_processor import ProcessorController
from texterify_processor.utils.console_output import ConsoleOutput
from version import get_version_string


class TexterifyProcessor:
    """
    Legacy wrapper for backward compatibility.
    DEPRECATED: Use ProcessorController directly.
    """

    def __init__(self, zip_path: str, config_path: str = None):
        """Initialize legacy processor."""
        self.controller = ProcessorController(zip_path, config_path)
        self.zip_path = Path(zip_path)

    def process(self) -> bool:
        """Process using the new architecture."""
        try:
            result = self.controller.process()
            return result.success
        except Exception as e:
            ConsoleOutput.print_error(str(e))
            return False


def main():
    """Main entry point for the CLI application"""
    parser = argparse.ArgumentParser(
        description=f"{get_version_string()} - Professional language file processing tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python texterify_processor.py "my_export.zip"
  python texterify_processor.py "export.zip" --config "custom_mappings.json"
  python texterify_processor.py "C:/exports/language_files.zip"

Features:
  - Configurable language file mappings via JSON config
  - Dynamic output filename formatting
  - Interactive conflict resolution: overwrite, add counter, or cancel
  - Case-sensitive or case-insensitive matching
  - Preserves all other files in the archive

Configuration:
  Edit config/language_mappings.json to customize:
  - Language mappings (source -> target filenames)
  - Output format settings
  - Processing behavior options

Conflict Resolution:
  When output file exists, you'll be prompted to:
  1. Overwrite existing file
  2. Add counter to create new file (lang_files_DD_MM_N.zip)
  3. Cancel operation
        """,
    )

    parser.add_argument(
        "zip_file", help="Path to the Texterify zip export file to process"
    )

    parser.add_argument(
        "--config", "-c", help="Path to custom language mappings configuration file"
    )

    parser.add_argument("--version", action="version", version=get_version_string())

    # Show help if no arguments provided
    if len(sys.argv) == 1:
        parser.print_help()
        print("\n💡 Tip: You can drag and drop a zip file onto this script!")
        print(f"🔧 {get_version_string()}")
        return

    args = parser.parse_args()

    # Process the file
    processor = TexterifyProcessor(args.zip_file, args.config)
    success = processor.process()

    if success:
        print("\n🎉 Processing completed successfully!")
    else:
        print("\n💥 Processing failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
