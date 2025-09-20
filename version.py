#!/usr/bin/env python3
"""
Texterify Language Processor - Version Configuration
==================================================

Centralized version management for the entire project.
Update this file to update version everywhere.

Author: Texterify Language Processor Team
License: MIT
"""

# Version Information
VERSION = "2.1.0"
VERSION_MAJOR = 2
VERSION_MINOR = 1
VERSION_PATCH = 0

# Project Information
PROJECT_NAME = "Texterify Language Processor"
PROJECT_DESCRIPTION = "Professional language file processing tool for Texterify exports"
PROJECT_AUTHOR = "Texterify Language Processor Team"
PROJECT_LICENSE = "MIT"
PROJECT_URL = "https://github.com/ecamlioglu/texterify-language-processor"

# Requirements
PYTHON_MIN_VERSION = "3.8"
PYTHON_RECOMMENDED_VERSION = "3.9+"

# Build Information
import datetime

BUILD_DATE = datetime.datetime.now().strftime("%Y-%m-%d")


def get_version_string():
    """Get formatted version string"""
    return f"{PROJECT_NAME} v{VERSION}"


def get_full_version_info():
    """Get complete version information"""
    return {
        "version": VERSION,
        "version_major": VERSION_MAJOR,
        "version_minor": VERSION_MINOR,
        "version_patch": VERSION_PATCH,
        "project_name": PROJECT_NAME,
        "description": PROJECT_DESCRIPTION,
        "author": PROJECT_AUTHOR,
        "license": PROJECT_LICENSE,
        "url": PROJECT_URL,
        "python_min": PYTHON_MIN_VERSION,
        "python_recommended": PYTHON_RECOMMENDED_VERSION,
        "build_date": BUILD_DATE,
    }


def print_version_info():
    """Print formatted version information"""
    print(f"{PROJECT_NAME} v{VERSION}")
    print(f"License: {PROJECT_LICENSE}")
    print(f"Python required: {PYTHON_MIN_VERSION}+")
    print(f"Build date: {BUILD_DATE}")


if __name__ == "__main__":
    print_version_info()
