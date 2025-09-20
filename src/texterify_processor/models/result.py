"""Result models for processing operations."""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional


@dataclass
class FileOperation:
    """Represents a file operation (rename, etc.)."""

    original_name: str
    new_name: str
    operation_type: str = "rename"


@dataclass
class ProcessingResult:
    """Result of a processing operation."""

    success: bool
    input_file: Path
    output_file: Optional[Path] = None
    file_operations: List[FileOperation] = None
    used_counter: bool = False
    counter_value: Optional[int] = None
    timestamp: datetime = None
    error_message: Optional[str] = None

    def __post_init__(self):
        if self.file_operations is None:
            self.file_operations = []
        if self.timestamp is None:
            self.timestamp = datetime.now()

    @property
    def processed_files_count(self) -> int:
        """Get the number of processed files."""
        return len(self.file_operations)

    def add_file_operation(self, original: str, new: str, operation: str = "rename"):
        """Add a file operation to the result."""
        self.file_operations.append(FileOperation(original, new, operation))

    def to_dict(self) -> dict:
        """Convert result to dictionary for serialization."""
        return {
            "success": self.success,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "input_file": str(self.input_file),
            "output_file": str(self.output_file) if self.output_file else None,
            "processed_files": self.processed_files_count,
            "file_operations": [
                {
                    "original": op.original_name,
                    "new": op.new_name,
                    "type": op.operation_type,
                }
                for op in self.file_operations
            ],
            "used_counter": self.used_counter,
            "counter_value": self.counter_value,
            "error_message": self.error_message,
        }
