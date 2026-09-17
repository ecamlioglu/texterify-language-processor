#!/usr/bin/env python3
"""Legacy script and boolean wrapper. New callers can use process_archive."""

from pathlib import Path

from texterify_processor import ProcessorController
from texterify_processor.cli import main


class TexterifyProcessor:
    def __init__(self, zip_path: str, config_path: str = None):
        self.controller = ProcessorController(zip_path, config_path)
        self.zip_path = Path(zip_path)

    def process(self) -> bool:
        return self.controller.process().success


if __name__ == "__main__":
    main()
