"""Service for file operations and transformations."""

import os
from pathlib import Path
from typing import List

from ..models.config import ProcessingConfig
from ..models.result import FileOperation
from ..utils.console_output import ConsoleOutput


class FileService:
    """Service for file operations and transformations."""

    def __init__(self, config: ProcessingConfig):
        self.config = config

    def find_and_rename_files(self, directory: Path) -> List[FileOperation]:
        """Find language files and rename them according to configuration."""
        operations = []

        for root, dirs, files in os.walk(directory):
            for file in files:
                file_path = Path(root) / file
                operation = self._try_rename_file(file_path)
                if operation:
                    operations.append(operation)

        return operations

    def _try_rename_file(self, file_path: Path) -> FileOperation:
        """Try to rename a single file based on configuration."""
        file_stem = file_path.stem

        # Check for language mapping
        target_name = self._get_target_name(file_stem)
        if not target_name:
            return None

        try:
            new_path = file_path.parent / target_name
            file_path.rename(new_path)

            ConsoleOutput.print_renamed_file(file_path.name, target_name)
            return FileOperation(
                original_name=file_path.name,
                new_name=target_name,
                operation_type="rename",
            )
        except Exception as e:
            ConsoleOutput.print_error(f"Failed to rename {file_path.name}: {e}")
            return None

    def _get_target_name(self, file_stem: str) -> str:
        """Get target name for a file stem based on language mappings."""
        for lang_key, lang_target in self.config.language_mappings.items():
            if self.config.case_sensitive:
                if file_stem == lang_key:
                    return lang_target
            else:
                if file_stem.lower() == lang_key.lower():
                    return lang_target
        return None

    def get_language_files_in_directory(self, directory: Path) -> List[str]:
        """Get list of language files in directory that match configuration."""
        language_files = []

        for root, dirs, files in os.walk(directory):
            for file in files:
                file_stem = Path(file).stem
                if self._get_target_name(file_stem):
                    language_files.append(file)

        return language_files
