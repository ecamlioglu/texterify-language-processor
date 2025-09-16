#!/usr/bin/env python3
"""
Version extraction utility for shell scripts
"""
import sys
from pathlib import Path

# Add the project root to path to import version
sys.path.append(str(Path(__file__).parent))

from version import VERSION, PROJECT_NAME, PROJECT_LICENSE, PYTHON_MIN_VERSION

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg == "version":
            print(VERSION)
        elif arg == "name":
            print(PROJECT_NAME)
        elif arg == "license":
            print(PROJECT_LICENSE)
        elif arg == "python":
            print(f"{PYTHON_MIN_VERSION}+")
        elif arg == "full":
            print(f"{PROJECT_NAME} v{VERSION}")
        else:
            print(VERSION)
    else:
        print(VERSION)
