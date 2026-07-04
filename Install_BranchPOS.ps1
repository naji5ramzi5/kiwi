<# 
.SYNOPSIS
    Fresh Branch POS Installer
.DESCRIPTION
    Installs Fresh Branch POS to Program Files and creates shortcuts.
#>

param(
    [switch]$Silent,
    [switch]$CreateDesktopShortcut = $true,
    [string]$InstallPath = "$env:ProgramFiles\Fresh Branch POS"
)

$ErrorActionPreference = "Stop"

$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceDir = Join-Path $sourceDir "BranchPOS"

if (-not (Test-Path $sourceDir)) {
    Write-Error "BranchPOS folder not found at: $sourceDir"
    exit 1
}

if (-not $Silent) {
    Write-Host "==========================================="
    Write-Host "  Fresh Branch POS Installer"
    Write-Host "==========================================="
    Write-Host "Installing to: $InstallPath"
}

# Create install directory
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Copy files
Write-Host "Copying files..." -NoNewline
Copy-Item -Path "$sourceDir\*" -Destination $InstallPath -Recurse -Force
Write-Host " Done"

# Create Desktop shortcut
if ($CreateDesktopShortcut) {
    $shortcutPath = Join-Path [Environment]::GetFolderPath('Desktop') "Fresh Branch POS.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $InstallPath "branch_pos.exe"
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.Description = "Fresh Branch POS"
    $shortcut.Save()
    Write-Host "Desktop shortcut created"
}

# Create Start Menu shortcut
$startMenuPath = Join-Path [Environment]::GetFolderPath('Programs') "Fresh Branch POS"
if (-not (Test-Path $startMenuPath)) { New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null }
$shortcutPath = Join-Path $startMenuPath "Fresh Branch POS.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $InstallPath "branch_pos.exe"
$shortcut.WorkingDirectory = $InstallPath
$shortcut.Description = "Fresh Branch POS"
$shortcut.Save()

# Add to PATH (optional)
# [Environment]::SetEnvironmentVariable("Path", $env:Path + ";" + $InstallPath, "Machine")

Write-Host "Installation complete!"
if (-not $Silent) {
    Write-Host "You can now run 'Fresh Branch POS' from Desktop or Start Menu."
    Read-Host "Press Enter to exit"
}

exit 0