#!/usr/bin/env python3
"""
Setup script for Texterify Language Processor
"""

from pathlib import Path
from setuptools import find_packages, setup

# Import version info
try:
    from version import PROJECT_AUTHOR, PROJECT_DESCRIPTION, PROJECT_NAME, VERSION
except ImportError:
    # Fallback values for build process
    PROJECT_AUTHOR = "Texterify Language Processor Team"
    PROJECT_DESCRIPTION = (
        "A professional tool for processing Texterify language export files"
    )
    PROJECT_NAME = "texterify-language-processor"
    VERSION = "2.1.0"

# Read the README file
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text(encoding="utf-8")

setup(
    name=PROJECT_NAME,
    version=VERSION,
    author=PROJECT_AUTHOR,
    description=PROJECT_DESCRIPTION,
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/your-username/texterify-language-processor",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Text Processing :: Linguistic",
    ],
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "texterify-processor=texterify_processor:main",
        ],
    },
    include_package_data=True,
    package_data={
        "texterify_processor": [
            "config/*.json",
        ],
    },
    zip_safe=False,
)
