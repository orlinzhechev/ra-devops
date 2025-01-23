# Fetch-VM-Config.ps1

param (
    [string]$VMName,               # Име на виртуалната машина
    [string]$HyperVServer = "localhost", # Име на Hyper-V сървъра (по подразбиране localhost)
    [string]$ConfigFile = ".\config-template.json", # Име на конфигурационния файл (по подразбиране)
    [switch]$GenerateTemplate,       # Опция за генериране на конфигурационен файл с шаблон
    [string]$OutputFile              # Опционално: име на генерирания файл
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

# Get Hard Disks and their sizes
$Disks = Get-VMHardDiskDrive -ComputerName $HyperVServer -VMName $VMName
$DiskDetails = @($Disks | ForEach-Object {
    $DiskPath = $_.Path
    $DiskSize = 0

    if ($HyperVServer -eq "localhost") {
        # Local server: Directly use Get-VHD
        if (Test-Path $DiskPath) {
            $DiskSize = (Get-VHD -Path $DiskPath).Size / 1GB
        } else {
            Write-Host "Warning: Disk '$DiskPath' does not exist." -ForegroundColor Yellow
        }
    } else {
        # Remote server: Use Invoke-Command
        try {
            $DiskSize = Invoke-Command -ComputerName $HyperVServer -ScriptBlock {
                param($Path)
                if (Test-Path $Path) {
                    (Get-VHD -Path $Path).Size / 1GB
                } else {
                    Write-Output 0
                }
            } -ArgumentList $DiskPath
        } catch {
            Write-Host "Error accessing disk '$DiskPath' on remote server: $_" -ForegroundColor Red
        }
    }

    [PSCustomObject]@{
        Path        = $DiskPath
        Controller  = $_.ControllerType
        SizeGB      = [math]::Round($DiskSize, 2)
    }
})

# Extract VM configuration
$VMConfig = @{
    VMName       = $VM.Name
    CPUs         = $Processor.Count
    RAM          = $Memory.StartupRAM
    Generation   = $VM.Generation
    ISOPath      = ($VM | Get-VMDvdDrive).Path
}

# Get Network Adapters
$NetworkAdapters = Get-VMNetworkAdapter -ComputerName $HyperVServer -VMName $VMName

# Adding network adapter details (SwitchName will remain only here)
$VMConfig.NetworkAdapters = @($NetworkAdapters | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.Name
        SwitchName  = $_.SwitchName
        MacAddress  = $_.MacAddress
    }
})

# Adding disk details
$VMConfig.Disks = $DiskDetails

# Convert configuration to JSON
$JSONConfig = $VMConfig | ConvertTo-Json -Depth 3

# Записваме конфигурацията с шаблонни стойности
$OutputDirectory = Join-Path -Path (Get-Location).Path -ChildPath "output"
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# Генериране на изходен файл
$OutputFilePath = if ($OutputFile) {
    Join-Path -Path $OutputDirectory -ChildPath $OutputFile
} elseif ($GenerateTemplate) {
    Join-Path -Path $OutputDirectory -ChildPath "config-template.json"
} else {
    Join-Path -Path $OutputDirectory -ChildPath "config-$VMName.json"
}

# Ако е зададен параметърът -GenerateTemplate, генерираме конфигурационен файл със стойности-шаблони
if ($GenerateTemplate) {
    # Заместете името на машината с шаблон
    $JSONConfig = $JSONConfig -replace $VMName, "{{VMName}}"
    $JSONConfig | Out-File -FilePath $OutputFilePath -Encoding utf8
    Write-Host "Template configuration saved to $OutputFilePath" -ForegroundColor Green
} else {
    # Ако не е зададен -GenerateTemplate, записваме конфигурацията със стойностите за виртуалната машина
    $JSONConfig | Out-File -FilePath $OutputFilePath -Encoding utf8
    Write-Host "Configuration saved to $OutputFilePath" -ForegroundColor Green
}

# Принтиране на съдържанието на генерирания конфигурационен файл
Write-Host "Generated configuration file content:" -ForegroundColor Cyan
Get-Content -Path $OutputFilePath | Out-String | Write-Host

