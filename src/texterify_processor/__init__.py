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
import importlib.util

import sys
from pathlib import Path

from .controllers.processor_controller import ProcessorController
from .models.config import ProcessingConfig
from .models.result import ProcessingResult

# Import main function from the legacy module (avoiding circular import)
sys.path.append(str(Path(__file__).parent.parent))

spec = importlib.util.spec_from_file_location(
    "texterify_processor_legacy",
    Path(__file__).parent.parent / "texterify_processor.py",
)
legacy_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy_module)
main = legacy_module.main

__all__ = ["ProcessorController", "ProcessingConfig", "ProcessingResult", "main"]
