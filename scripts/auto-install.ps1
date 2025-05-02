<#
.SYNOPSIS
    Auto-installs the latest Valheim modpack from GitHub into the game's root directory.

.DESCRIPTION
    - Detects the Valheim Steam installation path.
    - Downloads the latest release ZIP from the GitHub repo.
    - Extracts it into the Valheim root (not BepInEx).
    - Displays clear messages to the user.

.NOTES
    Author: Avarise
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "`n🔧 Starting Valheim Modpack Installer..." -ForegroundColor Cyan

# GitHub info
$repo = "Avarise/Valheim"
$releaseApi = "https://api.github.com/repos/$repo/releases/latest"
$tempZip = "$env:TEMP\Valheim-Modpack.zip"

# Attempt to detect Valheim install
function Get-ValheimPath {
    # Registry method (common for Steam installs)
    $key = 'HKCU:\Software\Valve\Steam'
    try {
        $steamPath = (Get-ItemProperty -Path $key).SteamPath
        if ($steamPath) {
            $libraryFoldersFile = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
            if (Test-Path $libraryFoldersFile) {
                $vdf = Get-Content $libraryFoldersFile -Raw
                $matches = Select-String -InputObject $vdf -Pattern '"path"\s+"([^"]+)"' -AllMatches
                foreach ($match in $matches.Matches) {
                    $libPath = $match.Groups[1].Value
                    $valheimPath = Join-Path $libPath "steamapps\common\Valheim"
                    if (Test-Path $valheimPath) {
                        return $valheimPath
                    }
                }
            }
        }
    } catch {}

    # Fallback guess
    $default = "$env:ProgramFiles(x86)\Steam\steamapps\common\Valheim"
    if (Test-Path $default) {
        return $default
    }

    return $null
}

$installDir = Get-ValheimPath

if (-not $installDir) {
    Write-Host "❌ Could not locate Valheim installation path." -ForegroundColor Red
    Read-Host "Please install Valheim via Steam and try again. Press Enter to exit"
    exit 1
}

Write-Host "✔ Valheim installation found at: $installDir" -ForegroundColor Green

# Download latest release zip
Write-Host "⬇ Downloading latest modpack from GitHub..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri $releaseApi -Headers @{ "User-Agent" = "PowerShell" }
    $asset = $response.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1

    if (-not $asset) {
        throw "No .zip asset found in latest release."
    }

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip
    Write-Host "✔ Downloaded modpack: $tempZip" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download release: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Extract to game root
Write-Host "📦 Extracting contents to: $installDir" -ForegroundColor Cyan
try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $installDir, $true)
    Write-Host "✅ Modpack installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to extract modpack: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Clean up
Remove-Item $tempZip -ErrorAction SilentlyContinue

Write-Host "`n🎮 All done! You may now launch Valheim through Steam." -ForegroundColor Cyan
Read-Host "Press Enter to close this window"
