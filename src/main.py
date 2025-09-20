#!/usr/bin/env python3
"""
Texterify Language Processor - Main Entry Point
===============================================

Professional language file processing tool for Texterify exports.
Refactored with proper OOP architecture and separation of concerns.

Author: Texterify Language Processor Team
License: MIT
"""

import argparse
import sys
from pathlib import Path

# Add the project root to the path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import after path modification
import texterify_processor as legacy_processor  # noqa: E402
from console_output import ConsoleOutput  # noqa: E402
from version import get_version_string  # noqa: E402


def create_argument_parser() -> argparse.ArgumentParser:
    """Create and configure the argument parser."""
    parser = argparse.ArgumentParser(
        description=(
            f"{get_version_string()} - Professional language file processing tool"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py "my_export.zip"
  python main.py "export.zip" --config "custom_mappings.json"
  python main.py "C:/exports/language_files.zip"

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

    return parser


def main():
    """Main entry point for the CLI application."""
    parser = create_argument_parser()

    # Show help if no arguments provided
    if len(sys.argv) == 1:
        parser.print_help()
        print("\n💡 Tip: You can drag and drop a zip file onto this script!")
        print(f"🔧 {get_version_string()}")
        return

    try:
        args = parser.parse_args()

        # Create and run the processor
        controller = legacy_processor.TexterifyProcessor(args.zip_file, args.config)
        result = controller.process()

        # Display results
        ConsoleOutput.print_result(result)
        ConsoleOutput.print_completion_message(result.success)

        if not result.success:
            sys.exit(1)

    except ValueError as e:
        ConsoleOutput.print_error(str(e))
        sys.exit(1)
    except KeyboardInterrupt:
        ConsoleOutput.print_warning("Operation interrupted by user")
        sys.exit(130)
    except Exception as e:
        ConsoleOutput.print_error(f"Unexpected error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
