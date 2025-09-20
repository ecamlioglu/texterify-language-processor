"""
Texterify Language Processor
============================

A professional tool for processing Texterify language export files.
Automatically renames language files according to configurable mappings
and creates date-stamped archives with interactive conflict resolution.

Author: Texterify Language Processor Team
License: MIT
"""

from .controllers.processor_controller import ProcessorController
from .models.config import ProcessingConfig
from .models.result import ProcessingResult

__all__ = ["ProcessorController", "ProcessingConfig", "ProcessingResult"]
