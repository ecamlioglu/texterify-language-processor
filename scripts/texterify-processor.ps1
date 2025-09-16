# Texterify Language Processor v2.0.0
# PowerShell Script for Windows
# Author: Texterify Language Processor Team
# License: MIT

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to the zip file to process")]
    [string]$ZipFile,
    
    [Parameter(HelpMessage="Show detailed output")]
    [switch]$Verbose,
    
    [Parameter(HelpMessage="Show version information")]
    [switch]$Version,
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script and project paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

# Function to get version information dynamically
function Get-VersionInfo {
    param([string]$InfoType = "version")
    
    try {
        $pythonCmd = $null
        if (Get-Command python3 -ErrorAction SilentlyContinue) {
            $pythonCmd = "python3"
        } elseif (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonCmd = "python"
        }
        
        if ($pythonCmd) {
            $versionScript = Join-Path $ProjectRoot "get_version.py"
            if (Test-Path $versionScript) {
                $result = & $pythonCmd $versionScript $InfoType 2>$null
                if ($result) { return $result }
            }
        }
    }
    catch {
        # Fallback
    }
    
    # Fallback values
    switch ($InfoType) {
        "version" { return "2.1.0" }
        "full" { return "Texterify Language Processor v2.1.0" }
        "license" { return "MIT" }
        "python" { return "3.6+" }
        default { return "2.1.0" }
    }
}

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Emoji = ""
    )
    
    if ($Emoji) {
        Write-Host "$Emoji $Message" -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Header {
    $versionInfo = Get-VersionInfo "full"
    Write-Host ""
    Write-ColoredOutput "================================================" "Magenta"
    Write-ColoredOutput "🌐 $versionInfo" "Magenta"
    Write-ColoredOutput "================================================" "Magenta"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColoredOutput $Message "Green" "✅"
}

function Write-Error {
    param([string]$Message)
    Write-ColoredOutput $Message "Red" "❌"
}

function Write-Warning {
    param([string]$Message)
    Write-ColoredOutput $Message "Yellow" "⚠️"
}

function Write-Info {
    param([string]$Message)
    Write-ColoredOutput $Message "Cyan" "📁"
}

function Write-Feature {
    param([string]$Message)
    Write-ColoredOutput $Message "Blue" "🔧"
}

# Function to show version information
function Show-Version {
    Write-Header
    Write-Host "$(Get-VersionInfo 'full')" -ForegroundColor White
    Write-Host "License: $(Get-VersionInfo 'license')" -ForegroundColor Gray
    Write-Host "Python required: $(Get-VersionInfo 'python')" -ForegroundColor Gray
    Write-Host "Platform: Windows PowerShell" -ForegroundColor Gray
    Write-Host ""
}

# Function to show usage information
function Show-Usage {
    Write-Header
    Write-Host "Usage: .\texterify-processor.ps1 <zip_file_path>" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -ZipFile <path>      Path to the Texterify zip export file" -ForegroundColor Gray
    Write-Host "  -Verbose             Show detailed output" -ForegroundColor Gray
    Write-Host "  -Version             Show version information" -ForegroundColor Gray
    Write-Host "  -Help                Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\texterify-processor.ps1 `"my_export.zip`"" -ForegroundColor Gray
    Write-Host "  .\texterify-processor.ps1 `"C:\Downloads\languages.zip`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Features:" -ForegroundColor Yellow
    Write-Feature "Renames 'en' files to: 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json"
    Write-Feature "Renames 'tr' files to: 26c7ace9-13fc-43b8-9988-2384fe670d03.json"
    Write-Feature "Creates date-stamped output: lang_files_DD_MM.zip"
    Write-Feature "Interactive conflict resolution: overwrite, add counter, or cancel"
    Write-Feature "Preserves all other files in the archive"
    Write-Host ""
    Write-ColoredOutput "Tip: You can drag and drop a zip file onto this script!" "Green" "💡"
    Write-ColoredOutput "$(Get-VersionInfo 'full')" "Magenta" "🌐"
}

# Function to check Python installation
function Test-PythonInstallation {
    try {
        # Try python3 first, then python
        $pythonCmd = $null
        
        if (Get-Command python3 -ErrorAction SilentlyContinue) {
            $pythonCmd = "python3"
        } elseif (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonCmd = "python"
        } else {
            throw "Python not found"
        }
        
        # Check Python version
        $pythonVersion = & $pythonCmd --version 2>&1
        Write-ColoredOutput "Using $pythonVersion" "Blue" "🐍"
        
        return $pythonCmd
    }
    catch {
        Write-Error "Python is not installed or not in PATH"
        Write-Host "Please install Python 3.7+ from https://python.org and try again" -ForegroundColor Yellow
        Write-Host "Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
        exit 1
    }
}

# Function to validate zip file
function Test-ZipFile {
    param([string]$FilePath)
    
    # Convert to absolute path
    try {
        $absolutePath = Resolve-Path $FilePath -ErrorAction Stop
        $FilePath = $absolutePath.Path
    }
    catch {
        Write-Error "Zip file not found: $FilePath"
        return $null
    }
    
    # Check if it's a zip file
    if (-not $FilePath.EndsWith('.zip', [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Error "File must be a .zip archive"
        return $null
    }
    
    # Check if file is readable
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        Write-Error "Cannot access zip file: $FilePath"
        return $null
    }
    
    return $FilePath
}


# Main execution
try {
    # Handle help and version flags first
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    if ($Version) {
        Show-Version
        exit 0
    }
    
    Write-Header
    
    # Validate input
    if (-not $ZipFile) {
        Write-Error "Zip file path is required"
        Show-Usage
        exit 1
    }
    
    # Validate zip file
    $validatedZipFile = Test-ZipFile -FilePath $ZipFile
    if (-not $validatedZipFile) {
        exit 1
    }
    
    Write-Info "Input: $(Split-Path -Leaf $validatedZipFile)"
    
    # Check Python installation
    $pythonCommand = Test-PythonInstallation
    
    # Construct path to Python script
    $pythonScript = Join-Path $ProjectRoot "src\texterify_processor.py"
    
    if (-not (Test-Path $pythonScript)) {
        Write-Error "Python script not found: $pythonScript"
        Write-Info "Make sure you're running this script from the project directory"
        exit 1
    }
    
    # Run the Python processor
    Write-Host ""
    Write-ColoredOutput "Starting Texterify Language Processor..." "Blue" "🚀"
    Write-Host "=================================================" -ForegroundColor Gray
    Write-Host ""
    
    # Execute Python script
    $processArgs = @($pythonScript, $validatedZipFile)
    $process = Start-Process -FilePath $pythonCommand -ArgumentList $processArgs -Wait -PassThru -NoNewWindow
    
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Gray
    
    if ($process.ExitCode -eq 0) {
        Write-Success "Processing completed successfully!"
        Write-Success "Your processed language files are ready!"
    } else {
        Write-Error "Processing failed!"
        Write-Error "Please check the error messages above"
        exit $process.ExitCode
    }
}
catch {
    Write-Host ""
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    if ($Verbose) {
        Write-Host $_.Exception.StackTrace -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "For help, run: .\texterify-processor.ps1 -Help" -ForegroundColor Yellow
    exit 1
}
finally {
    Write-Host ""
}
