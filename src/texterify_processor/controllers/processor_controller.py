"""Main controller for processing Texterify exports."""

import tempfile
from pathlib import Path
from typing import Optional

from ..models.config import ProcessingConfig
from ..models.result import ProcessingResult
from ..models.archive import ArchiveInfo
from ..services.config_service import ConfigService
from ..services.archive_service import ArchiveService
from ..services.file_service import FileService
from ..services.output_service import OutputService
from ..utils.user_interaction import UserInteraction, ConflictResolution
from ..utils.console_output import ConsoleOutput


class ProcessorController:
    """Main controller for orchestrating the processing workflow."""

    def __init__(self, zip_path: str, config_path: Optional[str] = None):
        """Initialize the processor controller."""
        self.zip_path = Path(zip_path).resolve()
        self.config = ConfigService.load_config(config_path)
        self.output_service = OutputService(self.config, self.zip_path.parent)
        self.file_service = FileService(self.config)

        # Validate configuration
        if not ConfigService.validate_config(self.config):
            raise ValueError("Invalid configuration")

    def process(self) -> ProcessingResult:
        """Main processing method."""
        result = ProcessingResult(success=False, input_file=self.zip_path)

        try:
            # Display header and input info
            import sys
            from pathlib import Path

            sys.path.append(str(Path(__file__).parent.parent.parent.parent))
            from version import get_version_string

            ConsoleOutput.print_header(get_version_string())
            ConsoleOutput.print_input_info(
                self.zip_path, list(self.config.language_mappings.keys())
            )

            # Validate archive
            archive_info = self._validate_archive()
            if not archive_info.is_valid:
                result.error_message = archive_info.error_message
                return result

            # Handle output file conflicts
            conflict_resolution = self._handle_output_conflicts()
            if conflict_resolution is None:
                result.error_message = "Operation cancelled by user"
                return result

            # Determine output filename
            output_filename, use_counter = self._get_output_filename(
                conflict_resolution
            )
            output_path = self.output_service.get_output_path(output_filename)

            # Process the archive
            success = self._process_archive(result, output_path)
            if success:
                result.success = True
                result.output_file = output_path
                result.used_counter = use_counter
                if use_counter:
                    result.counter_value = self._extract_counter_from_filename(
                        output_filename
                    )

            return result

        except Exception as e:
            result.error_message = str(e)
            return result

    def _validate_archive(self) -> ArchiveInfo:
        """Validate the input archive."""
        archive_info = ArchiveService.validate_archive(self.zip_path)
        if not archive_info.is_valid:
            ConsoleOutput.print_error(archive_info.error_message)
        return archive_info

    def _handle_output_conflicts(self) -> Optional[ConflictResolution]:
        """Handle conflicts with existing output files."""
        has_conflict, existing_filename = self.output_service.check_output_conflict()

        if not has_conflict:
            return ConflictResolution.OVERWRITE  # No conflict, proceed normally

        return UserInteraction.get_conflict_resolution(existing_filename)

    def _get_output_filename(self, resolution: ConflictResolution) -> tuple[str, bool]:
        """Get output filename based on conflict resolution."""
        if resolution == ConflictResolution.ADD_COUNTER:
            filename = self.output_service.generate_output_filename(use_counter=True)
            return filename, True
        else:
            filename = self.output_service.generate_output_filename(use_counter=False)
            return filename, False

    def _process_archive(self, result: ProcessingResult, output_path: Path) -> bool:
        """Process the archive and create output."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Extract archive
            ConsoleOutput.print_extraction_start()
            if not ArchiveService.extract_archive(self.zip_path, temp_path):
                result.error_message = "Failed to extract archive"
                return False

            # Find and rename language files
            file_operations = self.file_service.find_and_rename_files(temp_path)

            if not file_operations:
                ConsoleOutput.print_no_language_files_warning(
                    list(self.config.language_mappings.keys())
                )
                result.error_message = "No language files found to process"
                return False

            # Add operations to result
            result.file_operations = file_operations

            # Create output archive
            if not ArchiveService.create_archive(temp_path, output_path):
                result.error_message = "Failed to create output archive"
                return False

            return True

    def _extract_counter_from_filename(self, filename: str) -> Optional[int]:
        """Extract counter value from filename."""
        try:
            stem = Path(filename).stem
            parts = stem.split("_")
            if len(parts) >= 4:
                return int(parts[-1])
        except (ValueError, IndexError):
            pass
        return None
