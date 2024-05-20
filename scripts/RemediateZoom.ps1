# PowerShell script to uninstall Zoom silently
# (Add your RemediateZoom.ps1 script content here)
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

$uninstallLog = @()
$uninstallSuccessful = $true
$zoomNotInstalled = $true

# Create support folder and log file
$supportFolder = "C:\support"
if (-not (Test-Path -Path $supportFolder)) {
    New-Item -Path $supportFolder -ItemType Directory | Out-Null
}
$logFile = "$supportFolder\ZoomUninstallLog.txt"

# Initialize log
$uninstallLog += "Zoom Uninstall Script Log"
$uninstallLog += "=========================="
$uninstallLog += "Date: $(Get-Date)"
$uninstallLog += "Checked Paths:"

function Uninstall-Zoom {
    param (
        [string]$uninstallString
    )

    try {
        # Execute the uninstall command
        $uninstallProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString /quiet /norestart" -NoNewWindow -PassThru -Wait
        return $uninstallProcess.ExitCode
    } catch {
        Write-Output "Exception encountered while trying to uninstall: $_"
        return 1
    }
}

function Get-UninstallString {
    param (
        [string]$displayName
    )

    $uninstallString = ""

    # Search in HKLM
    $uninstallKeyHKLM = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $uninstallString = (Get-ItemProperty $uninstallKeyHKLM -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Zoom*" }).UninstallString
    if (-not $uninstallString) {
        # Search in HKLM 64-bit registry
        $uninstallKeyHKLM64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $uninstallString = (Get-ItemProperty $uninstallKeyHKLM64 -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Zoom*" }).UninstallString
    }

    # Search in HKCU
    if (-not $uninstallString) {
        $uninstallKeyHKCU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $uninstallString = (Get-ItemProperty $uninstallKeyHKCU -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Zoom*" }).UninstallString
    }

    return $uninstallString
}

foreach ($path in $zoomPaths) {
    $resolvedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    $uninstallLog += $path
    if ($resolvedPaths) {
        $zoomNotInstalled = $false
        foreach ($resolvedPath in $resolvedPaths) {
            $zoomExe = $resolvedPath.FullName
            try {
                # Try to find uninstall string from registry
                $uninstallString = Get-UninstallString "Zoom"

                if ($uninstallString) {
                    $uninstallLog += "Attempting to uninstall Zoom from $zoomExe"
                    $exitCode = Uninstall-Zoom $uninstallString
                    if ($exitCode -eq 0) {
                        $uninstallLog += "Success: Zoom uninstalled from $zoomExe"
                    } else {
                        $uninstallLog += "Error: Zoom uninstallation failed for $zoomExe with exit code $exitCode"
                        $uninstallSuccessful = $false
                    }
                } else {
                    $uninstallLog += "Error: Uninstall string not found for Zoom at $zoomExe"
                    $uninstallSuccessful = $false
                }
            } catch {
                $uninstallLog += "Error: Exception encountered while uninstalling Zoom from $zoomExe - $_"
                $uninstallSuccessful = $false
            }
        }
    } else {
        $uninstallLog += "No Zoom installation found at $path"
    }
}

if ($zoomNotInstalled) {
    $uninstallLog += "Good: No Zoom installed"
    Write-Output "Good: No Zoom installed"
    $uninstallLog | Out-File -FilePath $logFile -Encoding UTF8
    exit 0
} elseif ($uninstallSuccessful) {
    $uninstallLog += "Good: Zoom successfully uninstalled from all detected locations"
    Write-Output "Good: Zoom successfully uninstalled from all detected locations"
    $uninstallLog | Out-File -FilePath $logFile -Encoding UTF8
    exit 0
} else {
    $uninstallLog += "Error: Some Zoom installations could not be uninstalled"
    Write-Output "Error: Some Zoom installations could not be uninstalled"
    $uninstallLog | Out-File -FilePath $logFile -Encoding UTF8
    #exit 1
}
