"""Utility for handling user interactions."""

from enum import Enum

import sys
from typing import Optional


class ConflictResolution(Enum):
    """Enum for conflict resolution choices."""

    OVERWRITE = 1
    ADD_COUNTER = 2
    CANCEL = 3


class UserInteraction:
    """Utility class for user interactions."""

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
        if UserInteraction._supports_unicode():
            return {
                "warning": "⚠️ ",
                "note": "📝",
                "error": "❌",
            }
        else:
            return {
                "warning": "[WARN]",
                "note": "[NOTE]",
                "error": "[ERROR]",
            }

    @staticmethod
    def get_conflict_resolution(existing_filename: str) -> Optional[ConflictResolution]:
        """Get user choice for handling file conflicts."""
        symbols = UserInteraction._get_symbols()
        print(f"\n{symbols['warning']} Output file already exists: {existing_filename}")
        print("\nWhat would you like to do?")
        print("1. Overwrite existing file")
        print("2. Add counter to create new file")
        print("3. Cancel operation")

        while True:
            try:
                choice = input("\nEnter your choice (1-3): ").strip()

                if choice == "1":
                    print(f"{symbols['note']} Will overwrite existing file")
                    return ConflictResolution.OVERWRITE
                elif choice == "2":
                    print(f"{symbols['note']} Will create new file with counter")
                    return ConflictResolution.ADD_COUNTER
                elif choice == "3":
                    print(f"{symbols['error']} Operation cancelled by user")
                    return ConflictResolution.CANCEL
                else:
                    print(
                        f"{symbols['error']} Invalid choice. Please enter 1, 2, or 3."
                    )

            except (EOFError, KeyboardInterrupt):
                print(f"\n{symbols['error']} Operation cancelled by user")
                return ConflictResolution.CANCEL

    @staticmethod
    def confirm_action(message: str, default: bool = True) -> bool:
        """Get user confirmation for an action."""
        suffix = " [Y/n]" if default else " [y/N]"

        try:
            response = input(f"{message}{suffix}: ").strip().lower()

            if not response:
                return default

            return response in ["y", "yes", "true", "1"]

        except (EOFError, KeyboardInterrupt):
            return False
