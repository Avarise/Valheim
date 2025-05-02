$ErrorActionPreference = "Stop"

function Get-SteamLibraryPath {
    $regPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam"
    )
    foreach ($path in $regPaths) {
        try {
            $installPath = Get-ItemPropertyValue -Path $path -Name "SteamPath"
            if (Test-Path $installPath) {
                return $installPath
            }
        } catch {}
    }
    throw "Steam not found in registry."
}

function Get-ValheimInstallPath {
    $steamPath = Get-SteamLibraryPath
    $libraryFoldersPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    $libraryDirs = @($steamPath)
    if (Test-Path $libraryFoldersPath) {
        $libraryContent = Get-Content $libraryFoldersPath | Out-String
        $matches = Select-String -InputObject $libraryContent -Pattern '"path"\s+"([^"]+)"' -AllMatches
        foreach ($match in $matches.Matches) {
            $libraryDirs += $match.Groups[1].Value
        }
    }
    foreach ($dir in $libraryDirs) {
        $valheimPath = Join-Path $dir "steamapps\common\Valheim"
        if (Test-Path $valheimPath) {
            return $valheimPath
        }
    }
    throw "Valheim installation not found."
}

function Download-LatestReleaseZip {
    $repo = "Avarise/Valheim"
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    $headers = @{ "User-Agent" = "ValheimModInstaller" }
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    $asset = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    if (-not $asset) {
        throw "No zip asset found in the latest release."
    }
    $tempZip = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip
    return $tempZip
}

function Install-Modpack {
    $installPath = Get-ValheimInstallPath
    Write-Host "`n✔ Valheim installation found at: $installPath"
    $zipFile = Download-LatestReleaseZip
    Write-Host "⬇ Downloaded modpack: $zipFile"

    Write-Host "📦 Extracting contents to: $installPath"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $installPath, $true)

    Write-Host "`n✅ Modpack installed successfully to: $installPath"
}

Install-Modpack
Write-Host "`nAll done! You may now launch Valheim through Steam."
Pause
