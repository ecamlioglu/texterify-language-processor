"""Archive-related models."""

from dataclasses import dataclass

from pathlib import Path
from typing import List, Optional


@dataclass
class ArchiveInfo:
    """Information about an archive file."""

    path: Path
    is_valid: bool = False
    file_count: int = 0
    language_files: List[str] = None
    error_message: Optional[str] = None

    def __post_init__(self):
        if self.language_files is None:
            self.language_files = []

    @property
    def name(self) -> str:
        """Get archive filename."""
        return self.path.name

    @property
    def parent_dir(self) -> Path:
        """Get archive parent directory."""
        return self.path.parent

    def has_language_files(self) -> bool:
        """Check if archive contains any language files."""
        return len(self.language_files) > 0
