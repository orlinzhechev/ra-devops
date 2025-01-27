# Create-VM.ps1

param (
    [string]$VMName,               # Name of the virtual machine
    [string]$HyperVServer = "localhost", # Hyper-V server name (default is localhost)
    [string]$TargetPath,           # Target path for VM creation (e.g., C:\Hyper-V)
    [string]$ConfigFile,           # Configuration file name (default)
    [switch]$DryRun                # Simulate actions without making changes
)

Write-Host "Starting VM creation process..." -ForegroundColor Green

# Validate parameters
if (-not $VMName -or -not $TargetPath) {
    Write-Host "Error: Missing mandatory parameters!" -ForegroundColor Red
    exit
}

Write-Host "Parameters received:" -ForegroundColor Cyan
Write-Host "Hyper-V Server: $HyperVServer" -ForegroundColor Cyan
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "Target Disk: $TargetPath" -ForegroundColor Cyan
Write-Host "Configuration File: $ConfigFile" -ForegroundColor Cyan

# Check if the virtual machine already exists
Write-Host "Checking if VM '$VMName' already exists on '$HyperVServer'..." -ForegroundColor Yellow
if (-not $DryRun) {
    $ExistingVM = Get-VM -ComputerName $HyperVServer -Name $VMName -ErrorAction SilentlyContinue
    if ($ExistingVM) {
        Write-Host "WARNING: A VM with the name '$VMName' already exists. Aborting..." -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "DryRun: Simulating VM existence check." -ForegroundColor Yellow
}

# Load configuration from the file
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Host "Error: Configuration file not found at $ConfigFile" -ForegroundColor Red
    exit
}

Write-Host "Loading configuration file: $ConfigFile" -ForegroundColor Yellow
$Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
Write-Host "Configuration loaded successfully." -ForegroundColor Green

# Replace {{VMName}} with the provided VMName and update disk path
foreach ($disk in $Config.Disks) {
    $disk.Path = $disk.Path -replace '{{VMName}}', $VMName
    $disk.Path = $disk.Path -replace "^[A-Za-z]:\\Hyper-v", $TargetPath
}

$Config.VMName = $VMName
$Config.ISOPath = $Config.ISOPath -replace '{{VMName}}', $VMName

# Print updated configuration
Write-Host "Updated Configuration:" -ForegroundColor Cyan
$Config | ConvertTo-Json -Depth 3 | Write-Host

# Determine path creation method based on Hyper-V server
function Resolve-PathBasedOnServer {
    param (
        [string]$ServerName,
        [string]$BasePath,
        [string]$ChildPath
    )

    if ($ServerName -eq "localhost") {
        return Join-Path -Path $BasePath -ChildPath $ChildPath
    } else {
        return Invoke-Command -ComputerName $ServerName -ScriptBlock {
            param($basePath, $childPath)
            Join-Path -Path $basePath -ChildPath $childPath
        } -ArgumentList $BasePath, $ChildPath
    }
}

# Create directories for VM
$VMDiskPath = Resolve-PathBasedOnServer -ServerName $HyperVServer -BasePath $TargetPath -ChildPath "$VMName\Virtual Hard Disks"
Write-Host "Checking if directory for VM already exists on '$HyperVServer'..." -ForegroundColor Yellow
if (-not $DryRun) {
    $DirectoryExists = Invoke-Command -ComputerName $HyperVServer -ScriptBlock {
        param($path) Test-Path -Path $path
    } -ArgumentList $VMDiskPath

    if ($DirectoryExists) {
        Write-Host "Error: Directory '$VMDiskPath' already exists on $HyperVServer. Aborting..." -ForegroundColor Red
        exit
    }
} else {
    Write-Host "DryRun: Simulating directory existence check for $VMDiskPath." -ForegroundColor Yellow
}

Write-Host "Creating directories for VM configuration and disks..." -ForegroundColor Yellow
if (-not $DryRun) {
    Invoke-Command -ComputerName $HyperVServer -ScriptBlock {
        param($path) New-Item -ItemType Directory -Path $path -Force | Out-Null
    } -ArgumentList $VMDiskPath
} else {
    Write-Host "DryRun: Simulating creation of directories for VM at $VMDiskPath." -ForegroundColor Yellow
}

foreach ($disk in $Config.Disks) {
    # Generate disk name and path
    $FullPath = $disk.Path
    $DiskName = Split-Path -Path $FullPath -Leaf
    $NewDiskPath = Resolve-PathBasedOnServer -ServerName $HyperVServer -BasePath $VMDiskPath -ChildPath $DiskName
    Write-Host "New Disk Path: $NewDiskPath" -ForegroundColor Yellow

    # Check if the VHDX file already exists
    Write-Host "Checking if disk already exists..." -ForegroundColor Yellow
    if (-not $DryRun) {
        $DiskExists = Invoke-Command -ComputerName $HyperVServer -ScriptBlock {
            param($path) Test-Path -Path $path
        } -ArgumentList $NewDiskPath

        if ($DiskExists) {
            Write-Host "Error: VHDX file already exists at $NewDiskPath. Aborting..." -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "DryRun: Simulating VHDX existence check for $NewDiskPath." -ForegroundColor Yellow
    }
}

# Create the VM
Write-Host "Creating new VM: $VMName" -ForegroundColor Green
if (-not $DryRun) {
    New-VM -ComputerName $HyperVServer `
           -Name $VMName `
           -Generation $Config.Generation `
           -MemoryStartupBytes ([int]$Config.RAM * 1GB) `
           -Path $TargetPath
} else {
    Write-Host "DryRun: Simulating VM creation with name $VMName." -ForegroundColor Yellow
}

# Attach ISO file (if specified)
if ($Config.ISOPath -ne $null) {
    Write-Host "Attaching ISO file to VM (if available)..." -ForegroundColor Yellow
    if (-not $DryRun) {
        try {
            Add-VMDvdDrive -VMName $VMName -Path $Config.ISOPath -ComputerName $HyperVServer -Verbose
        } catch {
            Write-Host "ISO file not found or inaccessible. DVD drive added without ISO." -ForegroundColor Yellow
            Add-VMDvdDrive -VMName $VMName -ComputerName $HyperVServer -Verbose
        }
    } else {
        Write-Host "DryRun: Simulating attachment of ISO file at $($Config.ISOPath) to VM." -ForegroundColor Yellow
    }
} else {
    Write-Host "No ISO path specified. Adding DVD drive without ISO..." -ForegroundColor Yellow
    if (-not $DryRun) {
        Add-VMDvdDrive -VMName $VMName -ComputerName $HyperVServer -Verbose
    } else {
        Write-Host "DryRun: Simulating addition of DVD drive without ISO to VM." -ForegroundColor Yellow
    }
}

# Create new VHDX file
Write-Host "Creating new VHDX file at $NewDiskPath..." -ForegroundColor Yellow
foreach ($disk in $Config.Disks) {
    $FullPath = $disk.Path
    $DiskName = Split-Path -Path $FullPath -Leaf
    $NewDiskPath = Resolve-PathBasedOnServer -ServerName $HyperVServer -BasePath $VMDiskPath -ChildPath $DiskName
    if (-not $DryRun) {
        Write-Host "Creating VHDX disk at $NewDiskPath." -ForegroundColor Yellow
        try {
            New-VHD -Path $NewDiskPath -SizeBytes ($disk.SizeGB * 1GB) -Fixed -ComputerName $HyperVServer -Verbose
            Write-Host "VHDX file created successfully at $NewDiskPath." -ForegroundColor Green
            Write-Host "Attaching hard disk to VM..." -ForegroundColor Yellow
            Add-VMHardDiskDrive -VMName $VMName -Path $NewDiskPath -ComputerName $HyperVServer -Verbose
        }
        catch {
            Write-Error "Error: Cannot create disk: $_"
            exit
        }
    } else {
        Write-Host "DryRun: Simulating VHDX disk creation at $NewDiskPath." -ForegroundColor Yellow
    }
}


# Set CPU count
if (-not $DryRun) {
    Set-VM -Name $VMName -ProcessorCount $Config.CPUs -ComputerName $HyperVServer
} else {
    Write-Host "DryRun: Simulating CPU count setting to $($Config.CPUs)." -ForegroundColor Yellow
}

# Remove all existing network adapters
Write-Host "Removing all existing network adapters from VM..." -ForegroundColor Yellow
if (-not $DryRun) {
    $NetworkAdapters = Get-VMNetworkAdapter -VMName $VMName -ComputerName $HyperVServer
    if ($NetworkAdapters) {
        foreach ($adapter in $NetworkAdapters) {
            try {
                Remove-VMNetworkAdapter -VMName $VMName -Name $adapter.Name -ComputerName $HyperVServer -Verbose
            } catch {
                Write-Host "Error removing network adapter '$($adapter.Name)': $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No network adapters found to remove." -ForegroundColor Yellow
    }
} else {
    Write-Host "DryRun: Simulating removal of all network adapters from VM." -ForegroundColor Yellow
}

# Attach network adapters from configuration
Write-Host "Attaching network adapters to VM..." -ForegroundColor Yellow
foreach ($adapter in $Config.NetworkAdapters) {
    if (-not $DryRun) {
        Add-VMNetworkAdapter -VMName $VMName -SwitchName $adapter.SwitchName -ComputerName $HyperVServer -Verbose
    } else {
        Write-Host "DryRun: Simulating addition of network adapter with switch $($adapter.SwitchName)." -ForegroundColor Yellow
    }
}

Write-Host "VM '$VMName' successfully created on $HyperVServer with disk at $NewDiskPath." -ForegroundColor Green

