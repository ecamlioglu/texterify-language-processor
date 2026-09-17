"""Compatibility import; canonical version lives in the installable package."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / "src"))
from texterify_processor.version import *  # noqa: F401,F403,E402

if __name__ == "__main__":
    print_version_info()
