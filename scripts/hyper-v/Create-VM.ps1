# Create-VM.ps1

param (
    [string]$VMName,               # Name of the virtual machine
    [string]$HyperVServer = "localhost", # Hyper-V server name (default is localhost)
    [string]$TargetDisk,           # Target disk for VM creation (e.g., C:\Hyper-V)
    [string]$ConfigFile = ".\template-config.json" # Configuration file name (default)
)

Write-Host "Starting VM creation process..." -ForegroundColor Green

# Validate parameters
if (-not $VMName -or -not $TargetDisk) {
    Write-Host "Error: Missing mandatory parameters!" -ForegroundColor Red
    exit
}

Write-Host "Parameters received:" -ForegroundColor Cyan
Write-Host "Hyper-V Server: $HyperVServer" -ForegroundColor Cyan
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "Target Disk: $TargetDisk" -ForegroundColor Cyan
Write-Host "Configuration File: $ConfigFile" -ForegroundColor Cyan

# Check if the virtual machine already exists
Write-Host "Checking if VM '$VMName' already exists on '$HyperVServer'..." -ForegroundColor Yellow
$ExistingVM = Get-VM -ComputerName $HyperVServer -Name $VMName -ErrorAction SilentlyContinue
if ($ExistingVM) {
    Write-Host "WARNING: A VM with the name '$VMName' already exists. Aborting..." -ForegroundColor Yellow
    exit
}
Write-Host "No existing VM found. Proceeding with creation." -ForegroundColor Green

# Load configuration from the file
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Host "Error: Configuration file not found at $ConfigFile" -ForegroundColor Red
    exit
}

Write-Host "Loading configuration file: $ConfigFile" -ForegroundColor Yellow
$Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
Write-Host "Configuration loaded successfully." -ForegroundColor Green

# Replace {{VMName}} with the provided VMName
$Config.Disks.Path = $Config.Disks.Path -replace '{{VMName}}', $VMName
$Config.VMName = $VMName
$Config.ISOPath = $Config.ISOPath -replace '{{VMName}}', $VMName

# Print updated configuration
Write-Host "Updated Configuration:" -ForegroundColor Cyan
$Config | ConvertTo-Json -Depth 3 | Write-Host

# Create directories for VM
$VMDiskPath = Join-Path -Path $TargetDisk -ChildPath "$VMName\Virtual Hard Disks"
Write-Host "Creating directories for VM configuration and disks..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $VMDiskPath -Force | Out-Null

# Generate disk name and path
$DiskName = "$VMName`_os.vhdx"
$NewDiskPath = Join-Path -Path $VMDiskPath -ChildPath $DiskName
Write-Host "New Disk Path: $NewDiskPath" -ForegroundColor Yellow

# Check if the VHDX file already exists
if (Test-Path -Path $NewDiskPath) {
    Write-Host "Error: VHDX file already exists at $NewDiskPath. Aborting..." -ForegroundColor Red
    exit
}

# Create new VHDX file
Write-Host "Creating new VHDX file at $NewDiskPath..." -ForegroundColor Yellow
New-VHD -Path $NewDiskPath -SizeBytes ($Config.Disks.SizeGB * 1GB) -Fixed -Verbose
Write-Host "VHDX file created successfully at $NewDiskPath." -ForegroundColor Green

# Create the VM
Write-Host "Creating new VM: $VMName" -ForegroundColor Green
New-VM -ComputerName $HyperVServer `
       -Name $VMName `
       -Generation $Config.Generation `
       -MemoryStartupBytes ([int]$Config.RAM * 1GB) `
       -Path $TargetDisk   # Use base path directly

# Remove all existing network adapters
Write-Host "Removing all existing network adapters from VM..." -ForegroundColor Yellow
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

# Attach network adapters from configuration
Write-Host "Attaching network adapters to VM..." -ForegroundColor Yellow
foreach ($adapter in $Config.NetworkAdapters) {
    Add-VMNetworkAdapter -VMName $VMName -SwitchName $adapter.SwitchName -ComputerName $HyperVServer -Verbose
}

# Remove all network adapters from Boot Order
Write-Host "Removing all network adapters from Boot Order..." -ForegroundColor Yellow
try {
    $BootDevices = Get-VMFirmware -VMName $VMName -ComputerName $HyperVServer | Select-Object -ExpandProperty BootOrder | Where-Object { $_.BootEntryType -ne "NetworkAdapter" }
    Set-VMFirmware -VMName $VMName -BootOrder $BootDevices -ComputerName $HyperVServer
    Write-Host "Network adapters removed from Boot Order successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to adjust Boot Order: $_" -ForegroundColor Red
}

# Set CPU count
Set-VM -Name $VMName -ProcessorCount $Config.CPUs -ComputerName $HyperVServer

# Attach hard disks
Write-Host "Attaching hard disks to VM..." -ForegroundColor Yellow
$DiskPath = $Config.Disks.Path
Add-VMHardDiskDrive -VMName $VMName -Path $NewDiskPath -ComputerName $HyperVServer -Verbose

# Attach ISO file (if specified)
if ($Config.ISOPath -ne $null -and (Test-Path -Path $Config.ISOPath)) {
    Write-Host "Attaching ISO file to VM..." -ForegroundColor Yellow
    Add-VMDvdDrive -VMName $VMName -Path $Config.ISOPath -ComputerName $HyperVServer -Verbose
} else {
    Write-Host "No valid ISO file specified or found. Skipping DVD drive attachment." -ForegroundColor Yellow
}

Write-Host "VM '$VMName' successfully created on $HyperVServer with disk at $NewDiskPath." -ForegroundColor Green


