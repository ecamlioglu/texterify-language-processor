"""
Texterify Language Processor
============================

A professional tool for processing Texterify language export files.
Automatically renames language files according to configurable mappings
and creates date-stamped archives with interactive conflict resolution.

Author: Texterify Language Processor Team
License: MIT
"""

# Import main function from the legacy entry point
import sys
from pathlib import Path

from .controllers.processor_controller import ProcessorController
from .models.config import ProcessingConfig
from .models.result import ProcessingResult

sys.path.append(str(Path(__file__).parent.parent))
from texterify_processor import main  # noqa: E402

__all__ = ["ProcessorController", "ProcessingConfig", "ProcessingResult", "main"]
