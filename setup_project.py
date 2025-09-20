#!/usr/bin/env python3
"""
Project setup script for Texterify Language Processor
This script sets up the project for first use and verifies the environment.
"""

import sys
from pathlib import Path

# Import version info
from version import PROJECT_AUTHOR, PROJECT_DESCRIPTION, PROJECT_NAME, VERSION


def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Error: Python 3.8 or higher is required")
        print(f"   Current version: {sys.version}")
        return False

    print(f"✅ Python version: {sys.version.split()[0]} (compatible)")
    return True


def setup_project():
    """Set up the project for first use"""
    print(f"🚀 Setting up {PROJECT_NAME} v{VERSION}")
    print("=" * 60)

    # Check Python version
    if not check_python_version():
        sys.exit(1)

    # Check project structure
    required_dirs = ["src", "config", "scripts", "tests", "examples"]
    missing_dirs = []

    for dir_name in required_dirs:
        if not Path(dir_name).exists():
            missing_dirs.append(dir_name)
        else:
            print(f"✅ Directory exists: {dir_name}/")

    if missing_dirs:
        print(f"❌ Missing directories: {', '.join(missing_dirs)}")
        return False

    # Check required files
    required_files = [
        "src/texterify_processor.py",
        "config/language_mappings.json",
        "version.py",
        "get_version.py",
    ]

    missing_files = []
    for file_name in required_files:
        if not Path(file_name).exists():
            missing_files.append(file_name)
        else:
            print(f"✅ File exists: {file_name}")

    if missing_files:
        print(f"❌ Missing files: {', '.join(missing_files)}")
        return False

    # Make shell scripts executable (Unix-like systems)
    if sys.platform != "win32":
        import subprocess

        try:
            subprocess.run(
                ["chmod", "+x", "scripts/texterify-processor.sh"], check=True
            )
            print("✅ Made shell script executable")
        except subprocess.CalledProcessError:
            print(
                "⚠️  Could not make shell script executable (this is normal on Windows)"
            )

    print("\n" + "=" * 60)
    print("🎉 Setup completed successfully!")
    print("\n📖 Quick Start:")
    print("   python src/texterify_processor.py examples/sample_texterify_export.zip")
    print("\n🧪 Run Tests:")
    print("   python tests/run_tests.py")
    print("\n📚 Documentation:")
    print("   See README.md and examples/README.md")

    return True


if __name__ == "__main__":
    success = setup_project()
    sys.exit(0 if success else 1)
