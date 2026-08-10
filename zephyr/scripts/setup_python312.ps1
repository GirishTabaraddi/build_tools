# setup_python312.ps1
# Downloads and configures portable Python 3.12 in build_tools\Python312\
# No system Python is touched. No admin rights required.
# Run from the ROOT of your zephyr-course repo:
#   powershell -ExecutionPolicy Bypass -File tools/build_tools/zephyr/scripts/setup_python312.ps1

$ErrorActionPreference = "Stop"

# Resolve paths relative to repo root regardless of where you run this from
$RepoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..\..\..")).FullName
$BuildToolsRoot = Join-Path $RepoRoot "tools\build_tools"
$Python312Dir = Join-Path $BuildToolsRoot "Python312"
$Python312Exe = Join-Path $Python312Dir "python.exe"
$PthFile = Join-Path $Python312Dir "python312._pth"

# Pinned version - update this when Zephyr requires a newer 3.12.x patch
$PythonVersion = "3.12.10"
$PythonZip = "python-$PythonVersion-embed-amd64.zip"
$PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/$PythonZip"
$GetPipUrl = "https://bootstrap.pypa.io/get-pip.py"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Portable Python 3.12 Setup" -ForegroundColor Cyan
Write-Host " Target: $Python312Dir" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check what is already in Python312 ----------------------------
Write-Host "[1/6] Checking existing Python312 folder..." -ForegroundColor Yellow

if (Test-Path $Python312Exe) {
    $existingVer = (& $Python312Exe --version 2>&1)
    Write-Host "  Found: $existingVer at $Python312Exe" -ForegroundColor Green

    if ($existingVer -like "*3.12*") {
        Write-Host "  Already correct version (3.12.x). Checking pip..." -ForegroundColor Green
        $pipExe = Join-Path $Python312Dir "Scripts\pip.exe"
        if (Test-Path $pipExe) {
            Write-Host "  pip already present. Nothing to do." -ForegroundColor Green
            Write-Host ""
            Write-Host "  Python312 is ready. Use it with:" -ForegroundColor Cyan
            Write-Host "    $Python312Exe"
            exit 0
        } else {
            Write-Host "  pip missing - will install it now." -ForegroundColor Yellow
            # Jump straight to pip install (step 4)
            $skipDownload = $true
        }
    } else {
        Write-Host "  WRONG VERSION: $existingVer" -ForegroundColor Red
        Write-Host "  Zephyr requires Python 3.12. The existing version will cause problems." -ForegroundColor Red
        Write-Host "  Renaming existing folder to Python_old and installing 3.12..." -ForegroundColor Yellow
        $oldDir = Join-Path $BuildToolsRoot "Python_old_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Rename-Item $Python312Dir $oldDir
        Write-Host "  Old version saved at: $oldDir" -ForegroundColor Gray
    }
} else {
    Write-Host "  Python312 folder not found or empty. Will download." -ForegroundColor Yellow
}

# ---- Step 2: Download embedded Python 3.12 ----------------------------------
if (-not $skipDownload) {
    Write-Host ""
    Write-Host "[2/6] Downloading Python $PythonVersion embedded package (~12MB)..." -ForegroundColor Yellow

    New-Item -ItemType Directory -Force -Path $Python312Dir | Out-Null
    $ZipPath = Join-Path $Python312Dir $PythonZip

    Write-Host "  From: $PythonUrl"
    Invoke-WebRequest -Uri $PythonUrl -OutFile $ZipPath -UseBasicParsing
    Write-Host "  Downloaded: $ZipPath" -ForegroundColor Green

    # ---- Step 3: Extract it ---------------------------------------------------
    Write-Host ""
    Write-Host "[3/6] Extracting..." -ForegroundColor Yellow
    Expand-Archive -Path $ZipPath -DestinationPath $Python312Dir -Force
    Remove-Item $ZipPath  # cleanup zip
    Write-Host "  Extracted to: $Python312Dir" -ForegroundColor Green
}

# ---- Step 4: Enable site-packages in the .pth file --------------------------
# The embedded package ships with "import site" commented out.
# This disables pip, venv, and installed packages.
# We uncomment it to make pip work.
Write-Host ""
Write-Host "[4/6] Enabling site-packages (editing python312._pth)..." -ForegroundColor Yellow

if (Test-Path $PthFile) {
    $pthContent = Get-Content $PthFile -Raw
    if ($pthContent -match "#import site") {
        $pthContent = $pthContent -replace "#import site", "import site"
        Set-Content -Path $PthFile -Value $pthContent -NoNewline
        Write-Host "  Uncommented 'import site' in python312._pth" -ForegroundColor Green
    } else {
        Write-Host "  'import site' already enabled" -ForegroundColor Green
    }
} else {
    Write-Host "  WARNING: $PthFile not found. Manual edit may be needed." -ForegroundColor Red
}

# ---- Step 5: Install pip via get-pip.py -------------------------------------
Write-Host ""
Write-Host "[5/6] Installing pip..." -ForegroundColor Yellow
$GetPipScript = Join-Path $Python312Dir "get-pip.py"
Invoke-WebRequest -Uri $GetPipUrl -OutFile $GetPipScript -UseBasicParsing
& $Python312Exe $GetPipScript
Remove-Item $GetPipScript
Write-Host "  pip installed" -ForegroundColor Green

# ---- Step 6: Install virtualenv (more reliable than venv for embedded) ------
Write-Host ""
Write-Host "[6/6] Installing virtualenv..." -ForegroundColor Yellow
$PipExe = Join-Path $Python312Dir "Scripts\pip.exe"
& $PipExe install virtualenv
Write-Host "  virtualenv installed" -ForegroundColor Green

# ---- Summary ----------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Python 3.12 portable setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host " Interpreter: $Python312Exe"
Write-Host " Version:     " -NoNewline
& $Python312Exe --version
Write-Host ""
Write-Host " Create Zephyr venv with:"
Write-Host "   cd C:\Users\girish-tabaraddi\zephyrproject\zephyr-course"
Write-Host "   $Python312Exe -m virtualenv .venv"
Write-Host "   .\.venv\Scripts\Activate.ps1"
Write-Host "   pip install west"
Write-Host "============================================" -ForegroundColor Cyan