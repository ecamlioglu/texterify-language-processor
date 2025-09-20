"""Test helpers and compatibility wrappers."""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from texterify_processor import ProcessorController  # noqa: E402


class TexterifyProcessor:
    """
    Test compatibility wrapper for the old TexterifyProcessor interface.
    This allows existing tests to work with minimal changes.
    """

    def __init__(self, zip_path: str, config_path: str = None):
        """Initialize the wrapper."""
        self.controller = ProcessorController(zip_path, config_path)
        self.zip_path = self.controller.zip_path
        self.output_dir = self.controller.output_service.output_dir
        self.config = self.controller.config
        self.language_mappings = self.controller.config.language_mappings
        self.settings = {
            "case_sensitive": self.controller.config.case_sensitive,
            "preserve_extensions": self.controller.config.preserve_extensions,
            "backup_original": self.controller.config.backup_original,
            "output_format": {
                "date_format": self.controller.config.output_format.date_format,
                "base_filename": self.controller.config.output_format.base_filename,
                "extension": self.controller.config.output_format.extension,
            },
        }

    def process(self) -> bool:
        """Process using the new architecture and return boolean result."""
        try:
            result = self.controller.process()
            return result.success
        except Exception:
            return False

    def validate_zip_file(self) -> bool:
        """Validate zip file using the new architecture."""
        from texterify_processor.services.archive_service import ArchiveService

        archive_info = ArchiveService.validate_archive(self.zip_path)
        return archive_info.is_valid

    def generate_base_filename(self) -> str:
        """Generate base filename using the output service."""
        return self.controller.output_service._generate_base_filename()

    def generate_output_filename(self, use_counter: bool = False) -> str:
        """Generate output filename using the output service."""
        return self.controller.output_service.generate_output_filename(use_counter)
