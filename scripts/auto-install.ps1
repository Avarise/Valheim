# Enable error handling
$ErrorActionPreference = "Stop"

Write-Host "=== Valheim Modpack Auto-Installer ===" -ForegroundColor Cyan

# Function: Get the Valheim install path from Steam
function Get-ValheimInstallPath {
    Write-Host "Locating Steam installation..." -ForegroundColor Yellow

    $regPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\Software\WOW6432Node\Valve\Steam"
    )

    foreach ($path in $regPaths) {
        try {
            $steamPath = (Get-ItemProperty -Path $path).SteamPath
            if ($steamPath) {
                break
            }
        } catch {
            continue
        }
    }

    if (-not $steamPath) {
        throw "Could not locate Steam installation."
    }

    Write-Host "Steam found at: $steamPath" -ForegroundColor Green

    # Parse library folders
    $libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (-not (Test-Path $libraryFile)) {
        throw "libraryfolders.vdf not found at expected location: $libraryFile"
    }

    $vdf = Get-Content $libraryFile -Raw

    $matches = Select-String -InputObject $vdf -Pattern "\"path\"\s+\"([^\"]+)\"" -AllMatches
    $steamLibraries = @()
    foreach ($match in $matches.Matches) {
        $steamLibraries += $match.Groups[1].Value
    }

    # Append steamapps/common/Valheim
    foreach ($lib in $steamLibraries) {
        $valheimPath = Join-Path $lib "steamapps\common\Valheim"
        if (Test-Path $valheimPath) {
            Write-Host "Valheim installation found at: $valheimPath" -ForegroundColor Green
            return $valheimPath
        }
    }

    throw "Valheim installation not found in any Steam libraries."
}

# Function: Download and extract latest release zip
function Install-Modpack {
    param (
        [string]$installDir
    )

    Write-Host "Fetching latest release from GitHub..." -ForegroundColor Yellow

    $repo = "Avarise/Valheim"
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"

    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "Valheim-Mod-Installer" }

    $asset = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1

    if (-not $asset) {
        throw "No .zip asset found in the latest GitHub release."
    }

    $tempZip = [System.IO.Path]::GetTempFileName() + ".zip"

    Write-Host "Downloading: $($asset.name)" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip

    Write-Host "Extracting to: $installDir" -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $installDir, [System.Text.Encoding]::UTF8)

    Remove-Item $tempZip -Force

    Write-Host "Modpack installed successfully!" -ForegroundColor Green
}

# Main script execution
try {
    $installDir = Get-ValheimInstallPath
    Install-Modpack -installDir $installDir
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
