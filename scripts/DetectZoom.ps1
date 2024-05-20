# PowerShell script to detect Zoom installations
# (Add your DetectZoom.ps1 script content here)
$zoomPaths = @(
    "C:\Program Files (x86)\Zoom\bin\Zoom.exe",
    "C:\Program Files\Zoom\bin\Zoom.exe"
)

# Check all user profiles for AppData directories
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false } | Select-Object -ExpandProperty LocalPath
foreach ($profile in $userProfiles) {
    $zoomPaths += "$profile\AppData\Roaming\Zoom\bin\Zoom.exe"
    $zoomPaths += "$profile\AppData\Local\Zoom\bin\Zoom.exe"
}

$minVersion = [version]"6.0.4"
$foundOldVersion = $false
$zoomNotInstalled = $true
$logContent = @()

function ConvertTo-Version {
    param (
        [string]$versionString
    )
    
    # Split the version string into its components
    $versionParts = $versionString -split '[,\.]'
    if ($versionParts.Length -eq 4) {
        return [version]::new($versionParts[0], $versionParts[1], $versionParts[2], $versionParts[3])
    } elseif ($versionParts.Length -eq 3) {
        return [version]::new($versionParts[0], $versionParts[1], $versionParts[2])
    } else {
        throw "Invalid version string format: $versionString"
    }
}

# Create support folder and log file
$supportFolder = "C:\support"
if (-not (Test-Path -Path $supportFolder)) {
    New-Item -Path $supportFolder -ItemType Directory | Out-Null
}
$logFile = "$supportFolder\ZoomDetectionLog.txt"

# Initialize log
$logContent += "Zoom Detection Script Log"
$logContent += "=========================="
$logContent += "Date: $(Get-Date)"
$logContent += "Checked Paths:"

foreach ($path in $zoomPaths) {
    $resolvedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    $logContent += $path
    if ($resolvedPaths) {
        $zoomNotInstalled = $false
        foreach ($resolvedPath in $resolvedPaths) {
            $zoomVersionString = (Get-Item -Path $resolvedPath).VersionInfo.FileVersion
            try {
                $zoomVersion = ConvertTo-Version $zoomVersionString
                if ($zoomVersion -lt $minVersion) {
                    $logContent += "OLD: Zoom at $resolvedPath is older than version $minVersion"
                    $foundOldVersion = $true
                } else {
                    $logContent += "Good: Zoom at $resolvedPath is of valid version"
                }
            } catch {
                $logContent += "Error: Unable to parse version for Zoom at $resolvedPath"
            }
        }
    } else {
        $logContent += "No Zoom installation found at $path"
    }
}

if ($zoomNotInstalled) {
    $logContent += "Good: No Zoom installed"
    Write-Output "Good: No Zoom installed"
    $logContent | Out-File -FilePath $logFile -Encoding UTF8
    exit 0
} elseif ($foundOldVersion) {
    $logContent += "OLD: At least one Zoom installation is older than version $minVersion"
    Write-Output "OLD: At least one Zoom installation is older than version $minVersion"
    $logContent | Out-File -FilePath $logFile -Encoding UTF8
    exit 1
} else {
    $logContent += "Good: All Zoom installations are of valid version"
    Write-Output "Good: All Zoom installations are of valid version"
    $logContent | Out-File -FilePath $logFile -Encoding UTF8
    #exit 0
}
