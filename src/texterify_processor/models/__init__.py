"""Domain models for the Texterify Language Processor."""

from .archive import ArchiveInfo
from .config import OutputFormat, ProcessingConfig
from .result import FileOperation, ProcessingResult

__all__ = [
    "ProcessingConfig",
    "OutputFormat",
    "ProcessingResult",
    "FileOperation",
    "ArchiveInfo",
]
