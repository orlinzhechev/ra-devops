# Test remote disk creation

param (
    [switch]$DryRun, # Simulate the operation without making changes
    [string]$HyperVServer, # Remote Hyper-V server
    [string]$DiskPath,     # Full path to create the disk (e.g., E:\Hyper-V\test_disk.vhdx)
    [int]$SizeGB           # Size of the disk in GB
)

Write-Host "Starting remote disk creation test..." -ForegroundColor Green

# Validate parameters
if (-not $HyperVServer -or -not $DiskPath -or -not $SizeGB) {
    Write-Host "Error: Missing mandatory parameters!" -ForegroundColor Red
    Write-Host "Usage: .\Test-RemoteDisk.ps1 -HyperVServer <ServerName> -DiskPath <Path> -SizeGB <Size>" -ForegroundColor Yellow
    exit
}

Write-Host "Parameters received:" -ForegroundColor Cyan
Write-Host "Hyper-V Server: $HyperVServer" -ForegroundColor Cyan
Write-Host "Disk Path: $DiskPath" -ForegroundColor Cyan
Write-Host "Disk Size: $SizeGB GB" -ForegroundColor Cyan

# Test if the disk already exists
Write-Host "Checking if the disk already exists..." -ForegroundColor Yellow
try {
    $DiskExists = Invoke-Command -ComputerName $HyperVServer -ScriptBlock { param($path) Test-Path -Path $path } -ArgumentList $DiskPath
    if ($DiskExists) {
        Write-Host "Error: Disk already exists at $DiskPath. Aborting..." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "Error checking if the disk exists on $($HyperVServer): $_" -ForegroundColor Red
    exit
}

# Create the VHDX disk
if ($DryRun) {
    Write-Host "DryRun: Simulating VHDX disk creation at $DiskPath. No changes will be made." -ForegroundColor Yellow
} else {
    Write-Host "Creating the VHDX disk on the remote server..." -ForegroundColor Yellow
    try {
        New-VHD -Path $DiskPath -SizeBytes ($SizeGB * 1GB) -Fixed -ComputerName $HyperVServer -Verbose
        Write-Host "VHDX file successfully created at $DiskPath." -ForegroundColor Green
    } catch {
        Write-Host "Error creating the VHDX file: $_" -ForegroundColor Red
    }
}

