"""Service for handling archive operations."""

import zipfile
import tempfile
from pathlib import Path
from typing import List, Optional

from ..models.archive import ArchiveInfo
from ..models.config import ProcessingConfig


class ArchiveService:
    """Service for archive validation and extraction."""

    @staticmethod
    def validate_archive(archive_path: Path) -> ArchiveInfo:
        """Validate and get information about an archive."""
        archive_info = ArchiveInfo(path=archive_path)

        if not archive_path.exists():
            archive_info.error_message = f"Archive file not found: {archive_path}"
            return archive_info

        if not archive_path.suffix.lower() == ".zip":
            archive_info.error_message = "File must be a .zip archive"
            return archive_info

        try:
            with zipfile.ZipFile(archive_path, "r") as zf:
                # Test zip integrity
                if zf.testzip() is not None:
                    archive_info.error_message = "Archive is corrupted"
                    return archive_info

                # Get file information
                file_list = zf.namelist()
                archive_info.file_count = len(file_list)
                archive_info.language_files = ArchiveService._identify_language_files(
                    file_list, ProcessingConfig.get_default()
                )
                archive_info.is_valid = True

        except zipfile.BadZipFile:
            archive_info.error_message = "Invalid zip file format"
        except Exception as e:
            archive_info.error_message = f"Error validating archive: {str(e)}"

        return archive_info

    @staticmethod
    def extract_archive(archive_path: Path, destination: Path) -> bool:
        """Extract archive to destination directory."""
        try:
            with zipfile.ZipFile(archive_path, "r") as zf:
                zf.extractall(destination)
            return True
        except Exception:
            return False

    @staticmethod
    def create_archive(
        source_dir: Path, output_path: Path, compression_level: int = 6
    ) -> bool:
        """Create a zip archive from a directory."""
        try:
            with zipfile.ZipFile(
                output_path, "w", zipfile.ZIP_DEFLATED, compresslevel=compression_level
            ) as zf:
                for file_path in source_dir.rglob("*"):
                    if file_path.is_file():
                        arcname = file_path.relative_to(source_dir)
                        zf.write(file_path, arcname)
            return True
        except Exception:
            return False

    @staticmethod
    def _identify_language_files(
        file_list: List[str], config: ProcessingConfig
    ) -> List[str]:
        """Identify language files in the archive based on configuration."""
        language_files = []

        for file_path in file_list:
            file_name = Path(file_path).name
            file_stem = Path(file_path).stem

            # Check if this file matches any language mapping
            for lang_key in config.language_mappings.keys():
                if config.case_sensitive:
                    if file_stem == lang_key:
                        language_files.append(file_name)
                        break
                else:
                    if file_stem.lower() == lang_key.lower():
                        language_files.append(file_name)
                        break

        return language_files
