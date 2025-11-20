#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Universal network printer installation script with automatic driver support
.DESCRIPTION
    This script adds a TCP/IP printer port and installs the printer driver either from:
    - A local driver folder (manual .inf files)
    - Automatic download from Windows Update (for Lexmark M5270)
    - Manual download with guided instructions
.EXAMPLE
    .\Install-NetworkPrinter.ps1
#>

# ============================================
# CONFIGURATION - MODIFY THESE VALUES
# ============================================

# Printer configuration
$PrinterIPAddress = "10.10.78.62"          # IP address of the printer
$PrinterName = "Lexmark M5200 Series XL"              # Display name for the printer
$PortName = "IP_$PrinterIPAddress"           # Port name (will be created)

# Driver configuration mode
# Options: "LocalDriver" or "AutoDownload"
$DriverMode = "AutoDownload"                 # Change to "LocalDriver" to use manual driver files

# For LocalDriver mode:
$DriverName = "Lexmark M5200 Series XL"     # Exact name of the printer driver
$DriverInfPath = ".\Driver\*.inf"            # Path to the .inf file(s) relative to script location

# For AutoDownload mode (Lexmark M5270):
$AutoDriverNames = @(                        # List of driver names to try (in order of preference)
    "Lexmark M5200 Series XL",
    "Lexmark Universal v2 XL",
    "Lexmark M5270",
    "Lexmark Universal v2 PS3",
    "Lexmark Universal v2 UD1 XL"
)
$DriverDownloadURL = "https://support.lexmark.com/en_us/drivers-downloads.html?q=Lexmark+M5270"
$DriverDirectDownloadURL = "https://downloads.lexmark.com/downloads/drivers/Lexmark_Printer_Software_G3_Installation_Package_08222025.exe"
$DriverFolderPath = ".\Driver"               # Folder for manually downloaded drivers

# ============================================
# SCRIPT EXECUTION
# ============================================

# Get the script's directory (handles multiple execution contexts)
if ($PSScriptRoot) {
    $ScriptPath = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptPath = Get-Location
}
Set-Location $ScriptPath

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Universal Network Printer Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mode: $DriverMode" -ForegroundColor Magenta
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as Administrator'" -ForegroundColor Yellow
    Pause
    Exit 1
}

# ============================================
# STEP 1: CREATE PRINTER PORT
# ============================================
Write-Host "Step 1: Configuring printer port..." -ForegroundColor Yellow
$PortExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue

if ($PortExists) {
    Write-Host "  ✓ Port '$PortName' already exists." -ForegroundColor Green
} else {
    Write-Host "  Creating TCP/IP printer port for $PrinterIPAddress..." -ForegroundColor Yellow
    try {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIPAddress
        Write-Host "  ✓ Successfully created port '$PortName'" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ ERROR: Failed to create printer port!" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
        Pause
        Exit 1
    }
}

Write-Host ""

# ============================================
# STEP 2: INSTALL PRINTER DRIVER
# ============================================
Write-Host "Step 2: Installing printer driver..." -ForegroundColor Yellow

$InstalledDriver = $null
$DriverInstalled = $false

if ($DriverMode -eq "LocalDriver") {
    # ============================================
    # LOCAL DRIVER MODE
    # ============================================
    Write-Host "  Using local driver installation mode..." -ForegroundColor Cyan
    
    # Check if driver is already installed
    $DriverExists = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
    
    if ($DriverExists) {
        Write-Host "  ✓ Driver '$DriverName' is already installed." -ForegroundColor Green
        $InstalledDriver = $DriverName
        $DriverInstalled = $true
    } else {
        Write-Host "  Installing driver from local files..." -ForegroundColor Yellow
        
        # Find INF files
        $InfFiles = Get-ChildItem -Path $ScriptPath -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue | 
                    Where-Object { $_.FullName -like "*Driver*" }
        
        if ($InfFiles.Count -eq 0) {
            # Try alternate path
            $DriverFolder = Join-Path $ScriptPath "Driver"
            if (Test-Path $DriverFolder) {
                $InfFiles = Get-ChildItem -Path $DriverFolder -Filter "*.inf" -Recurse
            }
        }
        
        if ($InfFiles.Count -eq 0) {
            Write-Host "  ✗ ERROR: No INF files found!" -ForegroundColor Red
            Write-Host "  Expected location: $DriverInfPath" -ForegroundColor Yellow
            Write-Host "  Please ensure the driver files are in the correct location." -ForegroundColor Yellow
            Pause
            Exit 1
        }
        
        Write-Host "  Found $($InfFiles.Count) INF file(s). Installing to driver store..." -ForegroundColor Yellow
        
        foreach ($InfFile in $InfFiles) {
            try {
                Write-Host "    Processing: $($InfFile.Name)" -ForegroundColor Gray
                pnputil.exe /add-driver $InfFile.FullName /install | Out-Null
            } catch {
                Write-Host "    Warning: Could not process $($InfFile.Name)" -ForegroundColor Yellow
            }
        }
        
        # Add the printer driver
        try {
            Write-Host "  Adding printer driver '$DriverName'..." -ForegroundColor Yellow
            Add-PrinterDriver -Name $DriverName
            Write-Host "  ✓ Successfully installed driver '$DriverName'" -ForegroundColor Green
            $InstalledDriver = $DriverName
            $DriverInstalled = $true
        } catch {
            Write-Host "  ✗ ERROR: Failed to add printer driver!" -ForegroundColor Red
            Write-Host "  $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Troubleshooting tips:" -ForegroundColor Yellow
            Write-Host "  1. Verify the driver name matches exactly (case-sensitive)" -ForegroundColor Yellow
            Write-Host "  2. Check that all driver files are present" -ForegroundColor Yellow
            Write-Host "  3. Try running: Get-PrinterDriver to see available drivers" -ForegroundColor Yellow
            Pause
            Exit 1
        }
    }
    
} elseif ($DriverMode -eq "AutoDownload") {
    # ============================================
    # AUTO DOWNLOAD MODE (Lexmark M5270)
    # ============================================
    Write-Host "  Using automatic driver installation mode..." -ForegroundColor Cyan
    
    # Check if any of the drivers are already installed
    foreach ($DriverToCheck in $AutoDriverNames) {
        $DriverCheck = Get-PrinterDriver -Name $DriverToCheck -ErrorAction SilentlyContinue
        if ($DriverCheck) {
            $InstalledDriver = $DriverToCheck
            Write-Host "  ✓ Found installed driver: $InstalledDriver" -ForegroundColor Green
            $DriverInstalled = $true
            break
        }
    }
    
    if (-not $DriverInstalled) {
        Write-Host "  No compatible driver found. Attempting automatic installation..." -ForegroundColor Yellow
        Write-Host ""
        
        # Method 1: Try Windows Update
        Write-Host "  → Method 1: Searching Windows Update for driver..." -ForegroundColor Cyan
        Write-Host "    (This may take a few moments...)" -ForegroundColor Gray
        
        foreach ($DriverToTry in $AutoDriverNames) {
            try {
                Write-Host "    Trying: $DriverToTry" -ForegroundColor Gray
                Add-PrinterDriver -Name $DriverToTry -ErrorAction Stop
                Write-Host "  ✓ Successfully installed from Windows Update: $DriverToTry" -ForegroundColor Green
                $InstalledDriver = $DriverToTry
                $DriverInstalled = $true
                break
            } catch {
                # Continue to next driver option
            }
        }
        
        # Method 2: Try local driver folder
        if (-not $DriverInstalled) {
            Write-Host "  → Windows Update search completed (no driver found)." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  → Method 2: Checking for manually downloaded driver..." -ForegroundColor Cyan
            
            $DriverFolder = Join-Path $ScriptPath $DriverFolderPath
            if (Test-Path $DriverFolder) {
                Write-Host "  ✓ Found driver folder at: $DriverFolder" -ForegroundColor Green
                
                # Search for INF files
                $InfFiles = Get-ChildItem -Path $DriverFolder -Filter "*.inf" -Recurse
                
                if ($InfFiles.Count -gt 0) {
                    Write-Host "  Found $($InfFiles.Count) INF file(s). Installing..." -ForegroundColor Yellow
                    
                    foreach ($InfFile in $InfFiles) {
                        try {
                            Write-Host "    Processing: $($InfFile.Name)" -ForegroundColor Gray
                            pnputil.exe /add-driver $InfFile.FullName /install | Out-Null
                        } catch {
                            Write-Host "    Warning: Could not process $($InfFile.Name)" -ForegroundColor Yellow
                        }
                    }
                    
                    # Try to add driver again
                    foreach ($DriverToTry in $AutoDriverNames) {
                        try {
                            Add-PrinterDriver -Name $DriverToTry -ErrorAction Stop
                            Write-Host "  ✓ Successfully installed driver: $DriverToTry" -ForegroundColor Green
                            $InstalledDriver = $DriverToTry
                            $DriverInstalled = $true
                            break
                        } catch {
                            # Continue to next driver option
                        }
                    }
                } else {
                    Write-Host "  ✗ No INF files found in driver folder." -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ✗ Driver folder not found: $DriverFolder" -ForegroundColor Yellow
            }
        }
        
        # Method 3: Automatic download and install
        if (-not $DriverInstalled) {
            Write-Host "  → Method 3: Attempting automatic driver download..." -ForegroundColor Cyan
            Write-Host ""
            
            # Create temp directory in user's temp folder
            $TempDir = Join-Path $env:TEMP "LexmarkDriverInstall"
            if (-not (Test-Path $TempDir)) {
                New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
            }
            
            $DownloadPath = Join-Path $TempDir "LexmarkDriver.exe"
            $ExtractPath = Join-Path $TempDir "Extracted"
            
            try {
                Write-Host "  Downloading Lexmark driver package..." -ForegroundColor Yellow
                Write-Host "  Source: $DriverDirectDownloadURL" -ForegroundColor Gray
                Write-Host "  Destination: $DownloadPath" -ForegroundColor Gray
                Write-Host "  (This may take several minutes - file is ~500MB)" -ForegroundColor Gray
                Write-Host ""
                
                # Download with progress
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $DriverDirectDownloadURL -OutFile $DownloadPath -UseBasicParsing
                $ProgressPreference = 'Continue'
                
                Write-Host "  ✓ Download complete!" -ForegroundColor Green
                Write-Host ""
                
                # Find 7-Zip installation
                Write-Host "  Locating 7-Zip..." -ForegroundColor Yellow
                $7zipPaths = @(
                    "${env:ProgramFiles}\7-Zip\7z.exe",
                    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
                    "$env:ProgramData\chocolatey\bin\7z.exe"
                )
                
                $7zipExe = $null
                $7zipWasInstalled = $false
                foreach ($path in $7zipPaths) {
                    if (Test-Path $path) {
                        $7zipExe = $path
                        $7zipWasInstalled = $true
                        Write-Host "  ✓ Found 7-Zip at: $7zipExe" -ForegroundColor Green
                        break
                    }
                }
                
                if (-not $7zipExe) {
                    Write-Host "  ✗ 7-Zip not found. Installing 7-Zip..." -ForegroundColor Yellow
                    
                    # Check if winget is available
                    $WingetAvailable = $false
                    try {
                        $WingetVersion = winget --version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $WingetAvailable = $true
                            Write-Host "  ✓ Winget is available (version: $WingetVersion)" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  ✗ Winget is not available" -ForegroundColor Yellow
                    }
                    
                    # Install winget if missing
                    if (-not $WingetAvailable) {
                        Write-Host "  Installing winget (App Installer)..." -ForegroundColor Yellow
                        Write-Host "  (This may take a few minutes...)" -ForegroundColor Gray
                        
                        try {
                            # Download and install App Installer (contains winget)
                            $AppInstallerUrl = "https://aka.ms/getwinget"
                            $AppInstallerPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
                            
                            Write-Host "  Downloading App Installer..." -ForegroundColor Gray
                            Invoke-WebRequest -Uri $AppInstallerUrl -OutFile $AppInstallerPath -UseBasicParsing
                            
                            Write-Host "  Installing App Installer..." -ForegroundColor Gray
                            Add-AppxPackage -Path $AppInstallerPath -ErrorAction Stop
                            
                            # Wait for installation to complete
                            Start-Sleep -Seconds 5
                            
                            # Refresh environment and check again
                            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                            
                            try {
                                $WingetVersion = winget --version 2>&1
                                if ($LASTEXITCODE -eq 0) {
                                    $WingetAvailable = $true
                                    Write-Host "  ✓ Winget installed successfully (version: $WingetVersion)" -ForegroundColor Green
                                }
                            } catch {
                                Write-Host "  ✗ Winget still not available after installation" -ForegroundColor Yellow
                            }
                            
                            # Cleanup
                            if (Test-Path $AppInstallerPath) {
                                Remove-Item $AppInstallerPath -Force -ErrorAction SilentlyContinue
                            }
                        } catch {
                            Write-Host "  ✗ Failed to install winget: $_" -ForegroundColor Yellow
                            Write-Host "  You can install it manually from Microsoft Store (App Installer)" -ForegroundColor Yellow
                        }
                    }
                    
                    if ($WingetAvailable) {
                        # Install 7-Zip using winget
                        try {
                            Write-Host "  Installing 7-Zip via winget..." -ForegroundColor Gray
                            $WingetOutput = winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements 2>&1
                            Start-Sleep -Seconds 5
                            
                            # Refresh PATH environment variable
                            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                            
                            # Check again after install
                            foreach ($path in $7zipPaths) {
                                if (Test-Path $path) {
                                    $7zipExe = $path
                                    $7zipWasInstalled = $false  # We just installed it
                                    Write-Host "  ✓ 7-Zip installed successfully at: $7zipExe" -ForegroundColor Green
                                    break
                                }
                            }
                        } catch {
                            Write-Host "  ✗ Could not install 7-Zip via winget: $_" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "  ✗ Winget could not be installed. Cannot auto-install 7-Zip." -ForegroundColor Red
                        Write-Host "  Please install 7-Zip manually from: https://www.7-zip.org/" -ForegroundColor Yellow
                    }
                }
                
                if ($7zipExe) {
                    # Extract using 7-Zip
                    Write-Host "  Extracting Lexmark installer with 7-Zip..." -ForegroundColor Yellow
                    Write-Host "  (This may take 2-3 minutes...)" -ForegroundColor Gray
                    
                    if (-not (Test-Path $ExtractPath)) {
                        New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
                    }
                    
                    # Extract the EXE
                    $ExtractArgs = "x `"$DownloadPath`" -o`"$ExtractPath`" -y"
                    Start-Process -FilePath $7zipExe -ArgumentList $ExtractArgs -Wait -NoNewWindow
                    
                    Write-Host "  ✓ Extraction complete" -ForegroundColor Green
                    Write-Host ""
                    
                    # Find the print64xl.msi file
                    Write-Host "  Locating print64xl.msi..." -ForegroundColor Yellow
                    $MsiPath = Join-Path $ExtractPath "InstallationPackage\Drivers\x64\print64xl.msi"
                    
                    if (-not (Test-Path $MsiPath)) {
                        # Try to find it recursively
                        $MsiFiles = Get-ChildItem -Path $ExtractPath -Filter "print64xl.msi" -Recurse -ErrorAction SilentlyContinue
                        if ($MsiFiles) {
                            $MsiPath = $MsiFiles[0].FullName
                        }
                    }
                    
                    if (Test-Path $MsiPath) {
                        Write-Host "  ✓ Found: $MsiPath" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "  Installing Lexmark driver silently..." -ForegroundColor Yellow
                        Write-Host "  (This may take 2-3 minutes...)" -ForegroundColor Gray
                        
                        # Install the MSI silently
                        $MsiArgs = "/i `"$MsiPath`" /qn /norestart REBOOT=ReallySuppress"
                        $MsiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -Wait -PassThru -NoNewWindow
                        
                        if ($MsiProcess.ExitCode -eq 0 -or $MsiProcess.ExitCode -eq 3010) {
                            Write-Host "  ✓ MSI installation completed successfully" -ForegroundColor Green
                            
                            # Wait for driver files to be registered
                            Write-Host "  Waiting for driver files registration..." -ForegroundColor Gray
                            Write-Host "  (This can take 15-30 seconds...)" -ForegroundColor Gray
                            Start-Sleep -Seconds 15
                            
                            # Try to ADD the driver to Windows print subsystem (not just detect it)
                            # This is what Windows Update does - it adds the driver even if not "installed" yet
                            $MaxRetries = 6
                            $RetryDelay = 5
                            $RetryCount = 0
                            
                            Write-Host "  Adding driver to Windows print subsystem..." -ForegroundColor Yellow
                            
                            while (-not $DriverInstalled -and $RetryCount -lt $MaxRetries) {
                                $RetryCount++
                                
                                if ($RetryCount -gt 1) {
                                    Write-Host "  Retry $RetryCount/$MaxRetries - Attempting to add driver..." -ForegroundColor Gray
                                    Start-Sleep -Seconds $RetryDelay
                                }
                                
                                # Try to ADD each driver (this registers it with print subsystem)
                                foreach ($DriverToTry in $AutoDriverNames) {
                                    try {
                                        Add-PrinterDriver -Name $DriverToTry -ErrorAction Stop
                                        $InstalledDriver = $DriverToTry
                                        Write-Host "  ✓ Driver added successfully: $InstalledDriver" -ForegroundColor Green
                                        $DriverInstalled = $true
                                        break
                                    } catch {
                                        # Driver not available yet, continue to next one or retry
                                    }
                                }
                                
                                if ($DriverInstalled) {
                                    break
                                }
                            }
                            
                            # If adding by name failed, try to find and add any Lexmark M5xxx driver
                            if (-not $DriverInstalled) {
                                Write-Host ""
                                Write-Host "  Searching for installed driver files..." -ForegroundColor Yellow
                                
                                # Look in driver store for Lexmark drivers
                                try {
                                    # Get list of all available drivers from INF files
                                    $PnpOutput = pnputil.exe /enum-drivers 2>&1
                                    $LexmarkInfs = $PnpOutput | Select-String -Pattern "Lexmark.*M5" -Context 0,5
                                    
                                    if ($LexmarkInfs) {
                                        Write-Host "  ✓ Found Lexmark driver in driver store" -ForegroundColor Green
                                        
                                        # Try common Lexmark driver names
                                        $CommonNames = @(
                                            "Lexmark M5200 Series XL",
                                            "Lexmark M5270 XL", 
                                            "Lexmark MS MX Series XL",
                                            "Lexmark Universal v2 XL"
                                        )
                                        
                                        foreach ($DriverToTry in $CommonNames) {
                                            try {
                                                Add-PrinterDriver -Name $DriverToTry -ErrorAction Stop
                                                $InstalledDriver = $DriverToTry
                                                Write-Host "  ✓ Driver added successfully: $InstalledDriver" -ForegroundColor Green
                                                $DriverInstalled = $true
                                                break
                                            } catch {
                                                # Try next name
                                            }
                                        }
                                    }
                                } catch {
                                    # Continue to next check
                                }
                            }
                            
                            # Final check - see if ANY Lexmark driver is now available
                            if (-not $DriverInstalled) {
                                Write-Host ""
                                Write-Host "  Performing comprehensive driver check..." -ForegroundColor Yellow
                                Start-Sleep -Seconds 5
                                
                                $AllLexmarkDrivers = Get-PrinterDriver | Where-Object { $_.Name -like "*Lexmark*" }
                                if ($AllLexmarkDrivers) {
                                    Write-Host ""
                                    Write-Host "  ✓ Found registered Lexmark drivers:" -ForegroundColor Green
                                    foreach ($Driver in $AllLexmarkDrivers) {
                                        Write-Host "    - $($Driver.Name)" -ForegroundColor White
                                    }
                                    Write-Host ""
                                    
                                    # Prefer M5200 series
                                    $PreferredDriver = $AllLexmarkDrivers | Where-Object { $_.Name -like "*M5200*" -or $_.Name -like "*M5270*" -or $_.Name -like "*M52*" } | Select-Object -First 1
                                    if ($PreferredDriver) {
                                        $InstalledDriver = $PreferredDriver.Name
                                    } else {
                                        $InstalledDriver = $AllLexmarkDrivers[0].Name
                                    }
                                    
                                    Write-Host "  Using driver: $InstalledDriver" -ForegroundColor Green
                                    $DriverInstalled = $true
                                } else {
                                    Write-Host "  ℹ Driver files installed but not yet registered." -ForegroundColor Yellow
                                    Write-Host "  This is normal - Windows may need a reboot or more time." -ForegroundColor Yellow
                                }
                            }
                        } else {
                            Write-Host "  ✗ MSI installation failed with exit code: $($MsiProcess.ExitCode)" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "  ✗ Could not find print64xl.msi in extracted files" -ForegroundColor Red
                        Write-Host "  Searching for any MSI files..." -ForegroundColor Yellow
                        
                        $AllMsiFiles = Get-ChildItem -Path $ExtractPath -Filter "*.msi" -Recurse
                        if ($AllMsiFiles) {
                            Write-Host "  Found MSI files:" -ForegroundColor Cyan
                            foreach ($Msi in $AllMsiFiles) {
                                Write-Host "    - $($Msi.FullName)" -ForegroundColor White
                            }
                        }
                    }
                } else {
                    Write-Host "  ✗ 7-Zip not available. Cannot extract driver package." -ForegroundColor Red
                    Write-Host "  Please install 7-Zip from: https://www.7-zip.org/" -ForegroundColor Yellow
                    Write-Host "  Or the script will fall back to manual installation." -ForegroundColor Yellow
                }
                
                # Remove 7-Zip if we installed it
                if (-not $7zipWasInstalled -and $7zipExe) {
                    Write-Host ""
                    Write-Host "  Removing 7-Zip (was installed temporarily)..." -ForegroundColor Yellow
                    try {
                        # Check if winget is available
                        $WingetVersion = winget --version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            winget uninstall --id 7zip.7zip --silent 2>&1 | Out-Null
                            Write-Host "  ✓ 7-Zip removed successfully" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  ✗ Could not remove 7-Zip automatically" -ForegroundColor Yellow
                    }
                }
                
                # Cleanup temp directory
                Write-Host ""
                Write-Host "  Cleaning up temporary files..." -ForegroundColor Gray
                if (Test-Path $TempDir) {
                    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                
            } catch {
                Write-Host "  ✗ Automatic download failed: $_" -ForegroundColor Yellow
                Write-Host "  Falling back to manual download instructions..." -ForegroundColor Yellow
                
                # Cleanup on error
                if (Test-Path $TempDir) {
                    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Method 4: Manual download required
        if (-not $DriverInstalled) {
            Write-Host ""
            Write-Host "  → Method 4: Final driver check..." -ForegroundColor Cyan
            Write-Host "  Performing one last search for installed drivers..." -ForegroundColor Yellow
            
            # Give Windows a bit more time
            Start-Sleep -Seconds 5
            
            # Search for any Lexmark driver one final time
            $AllLexmarkDrivers = Get-PrinterDriver | Where-Object { $_.Name -like "*Lexmark*" }
            if ($AllLexmarkDrivers) {
                Write-Host ""
                Write-Host "  ✓ Found Lexmark drivers on final check:" -ForegroundColor Green
                foreach ($Driver in $AllLexmarkDrivers) {
                    Write-Host "    - $($Driver.Name)" -ForegroundColor White
                }
                Write-Host ""
                
                # Prefer M5200/M5270 series drivers
                $PreferredDriver = $AllLexmarkDrivers | Where-Object { $_.Name -like "*M5200*" -or $_.Name -like "*M5270*" -or $_.Name -like "*M52*" } | Select-Object -First 1
                if ($PreferredDriver) {
                    $InstalledDriver = $PreferredDriver.Name
                } else {
                    $InstalledDriver = $AllLexmarkDrivers[0].Name
                }
                
                Write-Host "  Using driver: $InstalledDriver" -ForegroundColor Green
                $DriverInstalled = $true
            }
        }
        
        # Method 5: Manual download prompt (only if still not found)
        if (-not $DriverInstalled) {
            Write-Host ""
            Write-Host "  ================================================" -ForegroundColor Red
            Write-Host "         MANUAL DRIVER DOWNLOAD REQUIRED" -ForegroundColor Red
            Write-Host "  ================================================" -ForegroundColor Red
            Write-Host ""
            Write-Host "  The printer driver could not be automatically installed." -ForegroundColor Yellow
            Write-Host "  Please download the driver manually:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  1. Visit: $DriverDownloadURL" -ForegroundColor White
            Write-Host "  2. Download 'Lexmark Printer Software G3' or 'Universal Print Driver'" -ForegroundColor White
            Write-Host "  3. Extract the downloaded file to: $DriverFolder" -ForegroundColor White
            Write-Host "  4. Run this script again" -ForegroundColor White
            Write-Host ""
            Write-Host "  Press any key to open the download page in your browser..." -ForegroundColor Cyan
            Pause
            Start-Process $DriverDownloadURL
            Exit 1
        }
    }
} else {
    Write-Host "  ✗ ERROR: Invalid DriverMode: $DriverMode" -ForegroundColor Red
    Write-Host "  Valid options: 'LocalDriver' or 'AutoDownload'" -ForegroundColor Yellow
    Pause
    Exit 1
}

Write-Host ""

# ============================================
# STEP 3: ADD PRINTER
# ============================================
Write-Host "Step 3: Adding printer..." -ForegroundColor Yellow
$PrinterExists = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue

if ($PrinterExists) {
    Write-Host "  ✓ Printer '$PrinterName' already exists." -ForegroundColor Green
    Write-Host "  To reinstall, remove the existing printer from Windows Settings first." -ForegroundColor Yellow
} else {
    try {
        Add-Printer -Name $PrinterName -DriverName $InstalledDriver -PortName $PortName
        Write-Host "  ✓ Successfully added printer '$PrinterName'" -ForegroundColor Green
        
        # Automatically set as default printer
        Write-Host "  Setting as default printer..." -ForegroundColor Yellow
        try {
            $PrinterFilter = "Name='" + $PrinterName + "'"
            $Printer = Get-CimInstance -ClassName Win32_Printer -Filter $PrinterFilter
            Invoke-CimMethod -InputObject $Printer -MethodName SetDefaultPrinter | Out-Null
            Write-Host "  ✓ Set as default printer." -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Could not set as default printer." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ ERROR: Failed to add printer!" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
        Pause
        Exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "           Installation Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Printer Details:" -ForegroundColor Cyan
Write-Host "  Name:       $PrinterName" -ForegroundColor White
Write-Host "  IP Address: $PrinterIPAddress" -ForegroundColor White
Write-Host "  Port:       $PortName" -ForegroundColor White
Write-Host "  Driver:     $InstalledDriver" -ForegroundColor White
Write-Host "  Mode:       $DriverMode" -ForegroundColor White
Write-Host "  Default:    Yes" -ForegroundColor White
Write-Host ""
Write-Host "The printer is ready to use!" -ForegroundColor Green
Write-Host ""
