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

    $steamPath = $null
    foreach ($path in $regPaths) {
        try {
            $steamPath = (Get-ItemProperty -Path $path).SteamPath
            if ($steamPath) { break }
        } catch {
            continue
        }
    }

    if (-not $steamPath) {
        throw "Could not locate Steam installation."
    }

    Write-Host "Steam found at: $steamPath" -ForegroundColor Green

    # Parse Steam library folders
    $libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (-not (Test-Path $libraryFile)) {
        throw "libraryfolders.vdf not found at expected location: $libraryFile"
    }

    $vdf = Get-Content $libraryFile -Raw

    $pattern = '"path"\s+"([^"]+)"'
    $matches = [regex]::Matches($vdf, $pattern)

    $steamLibraries = @()
    foreach ($match in $matches) {
        $steamLibraries += $match.Groups[1].Value
    }

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
    
    # Use fast streaming download
    $httpClient = New-Object System.Net.Http.HttpClient
    $response = $httpClient.GetAsync($asset.browser_download_url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

    $stream = $response.Content.ReadAsStreamAsync().Result
    $fileStream = [System.IO.File]::Create($tempZip)
    $stream.CopyTo($fileStream)

    $fileStream.Close()
    $stream.Close()
    $httpClient.Dispose()


    Write-Host "Extracting to: $installDir" -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $installDir)

    Remove-Item $tempZip -Force

    Write-Host "Modpack installed successfully!" -ForegroundColor Green
}

# Main script
try {
    $installDir = Get-ValheimInstallPath
    Install-Modpack -installDir $installDir
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
