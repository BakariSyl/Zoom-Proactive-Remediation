# ZoomDetectionRemediation

Scripts to detect and uninstall Zoom across multiple user profiles and system contexts.

## Overview

This repository contains two PowerShell scripts:

1. `DetectZoom.ps1`  - Detects Zoom installations and logs their locations and versions.

2. `RemediateZoom.ps1`  - Silently uninstalls detected Zoom installations and logs the results.

## Usage

Detection Script
----------------------------------------------------------------------------------------------
Run the detection script to identify all instances of Zoom installed on the system:

``powershell
scripts/DetectZoom.ps1
```

Remediation Script
----------------------------------------------------------------------------------------------
Run the remediation script to silently uninstall Zoom from all detected locations:

``powershell
scripts/RemediateZoom.ps1
```

## Logs

Logs are saved in the `C:\Support` directory on the system where the scripts are executed. Example logs are included in the `logs` directory.
