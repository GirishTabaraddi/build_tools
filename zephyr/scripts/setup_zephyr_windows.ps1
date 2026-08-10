# build_tools/zephyr/scripts/setup_zephyr_windows.ps1
# Install/verify Zephyr host dependencies on Windows
# Run: powershell -ExecutionPolicy Bypass -File tools/build_tools/zephyr/scripts/setup_zephyr_windows.ps1

$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$BuildToolsRoot = Join-Path $RepoRoot "tools\build_tools"
$SdkVersionFile = Join-Path $BuildToolsRoot "zephyr\sdk-config\sdk-version.txt"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Zephyr Course - Windows Dependency Setup" -ForegroundColor Cyan
Write-Host " Board: NUCLEO-C562RE (Cortex-M33)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Test-CommandExists {
    param($Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ---- CMake: prefer build_tools, fall back to system -------------------------
Write-Host "[1/7] CMake..." -ForegroundColor Yellow
$BuildToolsCMake = Join-Path $BuildToolsRoot "CMake\bin\cmake.exe"
if (Test-Path $BuildToolsCMake) {
    $ver = (& $BuildToolsCMake --version | Select-Object -First 1)
    Write-Host "  OK: build_tools CMake found - $ver" -ForegroundColor Green
    Write-Host "     NOTE: Verify this is >= 3.28.0 (Zephyr minimum)" -ForegroundColor Yellow
} elseif (Test-CommandExists "cmake") {
    $ver = (cmake --version | Select-Object -First 1)
    Write-Host "  OK: System CMake - $ver" -ForegroundColor Green
} else {
    Write-Host "  Installing CMake via winget..."
    winget install Kitware.CMake -e --source winget
}

# ---- Ninja: prefer build_tools ----------------------------------------------
Write-Host ""
Write-Host "[2/7] Ninja..." -ForegroundColor Yellow
$BuildToolsNinja = Join-Path $BuildToolsRoot "ninja-win\ninja.exe"
if (Test-Path $BuildToolsNinja) {
    Write-Host "  OK: ninja-win found in build_tools" -ForegroundColor Green
    Write-Host "     $BuildToolsNinja"
} elseif (Test-CommandExists "ninja") {
    Write-Host "  OK: System ninja found" -ForegroundColor Green
} else {
    Write-Host "  Installing Ninja via winget..."
    winget install Ninja-build.Ninja -e --source winget
}

# ---- Python 3.12 (Local build_tools installation) ---------------------------
Write-Host ""
Write-Host "[3/7] Python 3.12..." -ForegroundColor Yellow

$LocalPythonDir = Join-Path $BuildToolsRoot "python"
$LocalPythonExe = Join-Path $LocalPythonDir "python.exe"

if (Test-Path $LocalPythonExe) {
    $v = (& $LocalPythonExe --version 2>&1)
    Write-Host "  OK: Found local Python in build_tools - $v" -ForegroundColor Green
} else {
    Write-Host "  Local Python not found in $LocalPythonDir" -ForegroundColor Yellow
    Write-Host "  Downloading and installing Python 3.12 locally (this will not affect your system)..."
    
    # Define the specific 3.12 version to download
    $PythonVersion = "3.12.5" 
    $InstallerUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe"
    $InstallerPath = Join-Path $env:TEMP "python-$PythonVersion-amd64.exe"
    
    # Download the executable installer
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath
    
    # Arguments to install silently directly to build_tools, without touching system PATH
    $InstallArgs = "/quiet InstallAllUsers=0 TargetDir=`"$LocalPythonDir`" Include_pip=1 Include_test=0 Include_launcher=0 PrependPath=0"
    
    Write-Host "  Running installer (this may take a minute)..."
    Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -NoNewWindow
    
    # Cleanup the installer file
    Remove-Item $InstallerPath
    
    if (Test-Path $LocalPythonExe) {
        $v = (& $LocalPythonExe --version 2>&1)
        Write-Host "  OK: Python $v installed successfully to build_tools\python" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Python installation failed." -ForegroundColor Red
    }
}

# ---- gperf, dtc, wget, 7zip -------------------------------------------------
Write-Host ""
Write-Host "[4/7] Other Zephyr host tools (gperf, dtc, wget, 7zip)..." -ForegroundColor Yellow
$tools = @{
    "gperf"  = "oss-winget.gperf"
    "dtc"    = "oss-winget.dtc"
    "wget"   = "wget"
    "7z"     = "7zip.7zip"
}
foreach ($tool in $tools.Keys) {
    if (-not (Test-CommandExists $tool)) {
        Write-Host "  Installing $tool via winget..."
        winget install $tools[$tool] -e --source winget
    } else {
        Write-Host "  OK: $tool already installed" -ForegroundColor Green
    }
}

# ---- west (installed into venv later, not globally) -------------------------
Write-Host ""
Write-Host "[5/7] west (will be installed into Python venv during workspace init)..." -ForegroundColor Yellow
Write-Host "  west is installed via pip inside the Zephyr Python venv."
Write-Host "  Run: py -3.12 -m venv .venv"
Write-Host "  Then: .venv\Scripts\activate.bat"
Write-Host "  Then: pip install west"

# ---- Zephyr SDK -------------------------------------------------------------
Write-Host ""
Write-Host "[6/7] Zephyr SDK (arm-zephyr-eabi for Cortex-M33)..." -ForegroundColor Yellow
$SdkVersion = Get-Content $SdkVersionFile -ErrorAction SilentlyContinue
if (-not $SdkVersion) { $SdkVersion = "0.17.4" }
$SdkVersion = $SdkVersion.Trim()
$SdkPath = "C:\zephyr-sdk-$SdkVersion"
if (Test-Path $SdkPath) {
    Write-Host "  OK: Zephyr SDK $SdkVersion found at $SdkPath" -ForegroundColor Green
} else {
    Write-Host "  Zephyr SDK $SdkVersion not found at $SdkPath" -ForegroundColor Yellow
    Write-Host "  Install it after setting up your west workspace:"
    Write-Host "    cd <workspace>\zephyr"
    Write-Host "    west sdk install --toolchains arm-zephyr-eabi"
    Write-Host "  (Only ~400MB, not the full 12GB)"
}

# ---- Git submodules ---------------------------------------------------------
Write-Host ""
Write-Host "[7/7] Initializing git submodules..." -ForegroundColor Yellow
git submodule update --init --recursive
Write-Host "  OK: Submodules ready" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Setup complete! NEXT: initialize the west workspace." -ForegroundColor Green
Write-Host " See README.md for the west init + west update commands."
Write-Host "============================================" -ForegroundColor Cyan