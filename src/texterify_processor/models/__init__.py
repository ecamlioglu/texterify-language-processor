"""Domain models for the Texterify Language Processor."""

from .config import ProcessingConfig, OutputFormat
from .result import ProcessingResult, FileOperation
from .archive import ArchiveInfo

__all__ = [
    "ProcessingConfig",
    "OutputFormat",
    "ProcessingResult",
    "FileOperation",
    "ArchiveInfo",
]
