"""Service for managing output files and naming."""

from datetime import datetime
from pathlib import Path
from typing import Tuple

from ..models.config import ProcessingConfig


class OutputService:
    """Service for output file management and naming."""

    def __init__(self, config: ProcessingConfig, output_dir: Path):
        self.config = config
        self.output_dir = output_dir

    def generate_output_filename(self, use_counter: bool = False) -> str:
        """Generate output filename with optional counter."""
        base_filename = self._generate_base_filename()
        extension = self.config.output_format.extension

        if use_counter:
            counter = self._get_next_counter(base_filename)
            return f"{base_filename}_{counter}{extension}"

        return f"{base_filename}{extension}"

    def _generate_base_filename(self) -> str:
        """Generate base filename with current date."""
        now = datetime.now()
        date_part = now.strftime(self.config.output_format.date_format)
        return f"{self.config.output_format.base_filename}_{date_part}"

    def _get_next_counter(self, base_filename: str) -> int:
        """Auto-detect the next counter value for the current day."""
        pattern = f"{base_filename}_*.zip"
        existing_files = list(self.output_dir.glob(pattern))

        if not existing_files:
            return 1

        counters = []
        for file in existing_files:
            try:
                # Extract counter from filename like "lang_files_16_09_3.zip"
                parts = file.stem.split("_")
                if len(parts) >= 4:
                    counter = int(parts[-1])
                    counters.append(counter)
            except (ValueError, IndexError):
                continue

        return max(counters) + 1 if counters else 1

    def check_output_conflict(self) -> Tuple[bool, str]:
        """Check if output file would conflict with existing files."""
        base_filename = self._generate_base_filename()
        standard_filename = f"{base_filename}{self.config.output_format.extension}"
        standard_path = self.output_dir / standard_filename

        if standard_path.exists():
            return True, standard_filename
        return False, standard_filename

    def get_output_path(self, filename: str) -> Path:
        """Get full output path for a filename."""
        return self.output_dir / filename
