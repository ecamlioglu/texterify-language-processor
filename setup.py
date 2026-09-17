#!/usr/bin/env python3
"""
Setup script for Texterify Language Processor
"""

from pathlib import Path
from setuptools import find_packages, setup
from setuptools.command.build_py import build_py
import runpy
import shutil

metadata = runpy.run_path(str(Path(__file__).parent / "src/texterify_processor/version.py"))


class BuildWithConfig(build_py):
    """Package the repository's authoritative config without duplicating it in src."""
    def run(self):
        super().run()
        destination = Path(self.build_lib) / "texterify_processor/config"
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(Path(__file__).parent / "config/language_mappings.json", destination)

# Read the README file
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text(encoding="utf-8")

setup(
    name="texterify-language-processor",
    version=metadata["VERSION"],
    author=metadata["PROJECT_AUTHOR"],
    description=metadata["PROJECT_DESCRIPTION"],
    long_description=long_description,
    long_description_content_type="text/markdown",
    url=metadata["PROJECT_URL"],
    cmdclass={"build_py": BuildWithConfig},
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
