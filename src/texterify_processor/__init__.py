"""Texterify export processing for Python applications and the CLI."""

from .api import process_archive
from .controllers.processor_controller import ProcessorController
from .models.config import ProcessingConfig
from .models.result import ProcessingResult


def main():
    from .cli import main as cli_main

    return cli_main()


__all__ = [
    "ProcessorController",
    "ProcessingConfig",
    "ProcessingResult",
    "process_archive",
    "main",
]
