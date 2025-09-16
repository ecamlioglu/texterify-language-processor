#!/bin/bash

# Texterify Language Processor v2.0.0
# Unix/Linux/macOS Shell Script
# Author: Texterify Language Processor Team
# License: MIT

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get version information dynamically
get_version_info() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        # Fallback if Python not available
        echo "2.1.0" && return
    fi
    
    $PYTHON_CMD "$PROJECT_ROOT/get_version.py" "$1" 2>/dev/null || echo "2.1.0"
}

# Function to print colored output
print_header() {
    local version_info=$(get_version_info "full")
    echo -e "\n${PURPLE}================================================${NC}"
    echo -e "${PURPLE}🌐 $version_info${NC}"
    echo -e "${PURPLE}================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}📁 $1${NC}"
}

print_feature() {
    echo -e "${BLUE}🔧 $1${NC}"
}

# Function to check if Python is available
check_python() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        print_error "Python is not installed or not in PATH"
        echo "Please install Python 3.7+ and try again"
        echo "Visit: https://python.org/downloads"
        exit 1
    fi
    
    # Determine Python command
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
    
    # Check Python version
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    echo -e "${BLUE}🐍 Using Python $PYTHON_VERSION${NC}"
}

# Function to show usage
show_usage() {
    print_header
    echo "Usage: $0 <zip_file_path>"
    echo ""
    echo "Arguments:"
    echo "  zip_file_path    Path to the Texterify zip export file"
    echo ""
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --version, -v    Show version information"
    echo ""
    echo "Examples:"
    echo "  $0 \"my_texterify_export.zip\""
    echo "  $0 \"/path/to/language_files.zip\""
    echo ""
    echo "Features:"
    print_feature "Renames 'en' files to: 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json"
    print_feature "Renames 'tr' files to: 26c7ace9-13fc-43b8-9988-2384fe670d03.json"
    print_feature "Creates date-stamped output: lang_files_DD_MM.zip"
    print_feature "Interactive conflict resolution: overwrite, add counter, or cancel"
    print_feature "Preserves all other files in the archive"
    echo ""
    echo "💡 Tip: You can drag and drop a zip file onto this script!"
    echo "🌐 $(get_version_info 'full')"
}

# Function to validate zip file
validate_zip() {
    local zip_file="$1"
    
    # Check if file exists
    if [[ ! -f "$zip_file" ]]; then
        print_error "Zip file not found: $zip_file"
        return 1
    fi
    
    # Check if it's a zip file
    if [[ ! "$zip_file" =~ \.zip$ ]]; then
        print_error "File must be a .zip archive"
        return 1
    fi
    
    # Check if file is readable
    if [[ ! -r "$zip_file" ]]; then
        print_error "Cannot read zip file: $zip_file"
        return 1
    fi
    
    return 0
}


# Main function
main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    # Handle help and version flags
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --version|-v)
            echo "$(get_version_info 'full')"
            echo "License: $(get_version_info 'license')"
            echo "Python required: $(get_version_info 'python')"
            exit 0
            ;;
    esac
    
    local zip_file="$1"
    
    # Check for unknown arguments
    if [[ $# -gt 1 ]]; then
        print_error "Unknown argument: $2"
        echo "Use --help for usage information"
        exit 1
    fi
    
    print_header
    
    # Convert to absolute path
    zip_file="$(realpath "$zip_file")"
    
    print_info "Input: $(basename "$zip_file")"
    
    # Validate zip file
    if ! validate_zip "$zip_file"; then
        exit 1
    fi
    
    # Check Python availability
    check_python
    
    # Construct Python script path
    PYTHON_SCRIPT="$PROJECT_ROOT/src/texterify_processor.py"
    
    if [[ ! -f "$PYTHON_SCRIPT" ]]; then
        print_error "Python script not found: $PYTHON_SCRIPT"
        print_info "Make sure you're running this script from the project directory"
        exit 1
    fi
    
    # Run the Python processor
    echo -e "\n${BLUE}🚀 Starting Texterify Language Processor...${NC}"
    echo "================================================="
    echo ""
    
    if $PYTHON_CMD "$PYTHON_SCRIPT" "$zip_file"; then
        echo ""
        echo "================================================="
        print_success "Processing completed successfully!"
        print_success "Your processed language files are ready!"
    else
        echo ""
        echo "================================================="
        print_error "Processing failed!"
        print_error "Please check the error messages above"
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}⚠️  Operation cancelled by user${NC}"; exit 130' INT

# Run main function with all arguments
main "$@"
