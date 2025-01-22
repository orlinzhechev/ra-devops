param (
    [string]$VMName,               # Име на виртуалната машина
    [string]$HyperVServer = "localhost", # Име на Hyper-V сървъра (по подразбиране localhost)
    [string]$ConfigFile = ".\template-config.json", # Име на конфигурационния файл (по подразбиране)
    [switch]$GenerateTemplate       # Опция за генериране на конфигурационен файл с шаблон
)

Write-Host "Fetching configuration for VM '$VMName' on server '$HyperVServer'..." -ForegroundColor Green

# Зареждаме конфигурацията от съществуваща виртуална машина
$VM = Get-VM -ComputerName $HyperVServer -Name $VMName
if (-not $VM) {
    Write-Host "Error: VM '$VMName' not found on '$HyperVServer'." -ForegroundColor Red
    exit
}

# Извличане на конфигурация за дискове и мрежови адаптери
$VHD = Get-VMHardDiskDrive -ComputerName $HyperVServer -VMName $VMName
$Memory = @{ StartupRAM = [math]::Round((Get-VM -ComputerName $HyperVServer -Name $VMName).MemoryStartup / 1GB, 0) }
$Processor = Get-VMProcessor -ComputerName $HyperVServer -VMName $VMName

# Get Network Adapters
$NetworkAdapters = Get-VMNetworkAdapter -ComputerName $HyperVServer -VMName $VMName

# Get Hard Disks and their sizes
$Disks = Get-VMHardDiskDrive -ComputerName $HyperVServer -VMName $VMName
$DiskDetails = $Disks | ForEach-Object {
    $DiskSize = (Get-VHD -Path $_.Path).Size / 1GB
    [PSCustomObject]@{
        Name        = $_.Name
        Path        = $_.Path
        Controller  = $_.ControllerType
        SizeGB      = [math]::Round($DiskSize, 2)
    }
}

# Extract VM configuration
$VMConfig = @{
    VMName       = $VM.Name
    CPUs         = $Processor.Count
    RAM          = $Memory.StartupRAM
    Generation   = $VM.Generation
    ISOPath      = ($VM | Get-VMDvdDrive).Path
}

# Adding network adapter details (SwitchName will remain only here)
$VMConfig.NetworkAdapters = $NetworkAdapters | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.Name
        SwitchName  = $_.SwitchName
        MacAddress  = $_.MacAddress
    }
}

# Adding disk details
$VMConfig.Disks = $DiskDetails

# Convert configuration to JSON
$JSONConfig = $VMConfig | ConvertTo-Json -Depth 3

# Записваме конфигурацията с шаблонни стойности
$OutputDirectory = Join-Path -Path (Get-Location).Path -ChildPath "output"
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# Ако е зададен параметърът -GenerateTemplate, генерираме конфигурационен файл със стойности-шаблони
if ($GenerateTemplate) {
    # Заместете името на машината с шаблон
    $JSONConfig = $JSONConfig -replace $VMName, "{{VMName}}"
    $JSONConfig | Out-File -FilePath "$OutputDirectory\template-config.json" -Encoding utf8
    Write-Host "Template configuration saved to $OutputDirectory\template-config.json" -ForegroundColor Green
} else {
    # Ако не е зададен -GenerateTemplate, записваме конфигурацията със стойностите за виртуалната машина
    $JSONConfig | Out-File -FilePath "$OutputDirectory\$VMName-config.json" -Encoding utf8
    Write-Host "Configuration saved to $OutputDirectory\$VMName-config.json" -ForegroundColor Green
}

# Принтиране на съдържанието на генерирания конфигурационен файл
Write-Host "Generated configuration file content:" -ForegroundColor Cyan
Get-Content -Path "$OutputDirectory\$VMName-config.json" | Out-String | Write-Host

# Ако е зададен параметърът -GenerateTemplate, принтираме съдържанието на шаблона
if ($GenerateTemplate) {
    Write-Host "Generated template configuration file content:" -ForegroundColor Cyan
    Get-Content -Path "$OutputDirectory\template-config.json" | Out-String | Write-Host
}

