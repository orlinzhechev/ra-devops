<#
    Script: Check-BuildModules.ps1
    Description: Checks installed modules based on the "build-win" Ansible role.
    Note: For modules where a reliable check is not clear, the check is skipped (to be implemented).
#>

###########################
# Helper Functions        #
###########################

# Helper function to check for the .NET SDK executable in common locations.
function Test-DotNetSDK {
    $paths = @(
        "C:\Program Files\dotnet\dotnet.exe",
        "C:\Program Files (x86)\dotnet\dotnet.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            return $true
        }
    }
    # Fallback to Get-Command if not found in the above locations.
    return (Get-Command dotnet -ErrorAction SilentlyContinue) -ne $null
}

# Generic function to run a module check scriptblock and return a status object.
function Check-Module {
    param (
        [string]$ModuleName,
        [scriptblock]$CheckScript
    )
    try {
        if (& $CheckScript) {
            return @{ Name = $ModuleName; Status = "OK" }
        }
        else {
            return @{ Name = $ModuleName; Status = "Failed" }
        }
    }
    catch {
        return @{ Name = $ModuleName; Status = "Failed" }
    }
}

###########################
# .NET Framework 4.6 Tasks #
###########################
function Check-DotNet46 {
    Write-Host "Status for .NET Framework 4.6 Components"
    $modules = @()

    $modules += Check-Module -ModuleName ".NET SDK (dotnet-sdk)" -CheckScript { Test-DotNetSDK }
    $modules += @{ Name = ".NET Framework 4.6 Developer Pack (netfx-4.6-devpack)"; Status = "Skipped (to be implemented)" }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -notin @("OK", "Skipped (to be implemented)")) { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for .NET 4.6: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# .NET Framework 4.8 Tasks #
###########################
function Check-DotNet48 {
    Write-Host "Status for .NET Framework 4.8 Components"
    $modules = @()

    $modules += Check-Module -ModuleName ".NET SDK (dotnet-sdk)" -CheckScript { Test-DotNetSDK }
    $modules += Check-Module -ModuleName ".NET 9.0 SDK" -CheckScript {
        $sdks = (& "C:\Program Files\dotnet\dotnet.exe" --list-sdks 2>$null)
        if ($sdks) { return $sdks -match '^9\.' }
        return $false
    }
    $modules += @{ Name = ".NET Framework 4.8 Developer Pack (netfx-4.8.1)"; Status = "Skipped (to be implemented)" }
    $modules += @{ Name = ".NET Framework 4.8 Development Tools (netfx-4.8-devpack)"; Status = "Skipped (to be implemented)" }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -notin @("OK", "Skipped (to be implemented)")) { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for .NET 4.8: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# WiX Toolset Tasks       #
###########################
function Check-WiX {
    Write-Host "Status for WiX Toolset"
    $modules = @()

    $modules += Check-Module -ModuleName "WiX Toolset Installation (Program Files)" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\WiX Toolset v3.14")
    }
    $modules += Check-Module -ModuleName "WiX symlink in VS2019 path" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Microsoft\WiX\v3.x")
    }
    $modules += Check-Module -ModuleName "WiX Package in ProgramData" -CheckScript {
        return (Test-Path "C:\ProgramData\chocolatey\lib\wixtoolset")
    }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -ne "OK") { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for WiX: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# Visual Studio 2019 Tasks#
###########################
function Check-VS2019 {
    Write-Host "Status for Visual Studio 2019 Components"
    $modules = @()

    $modules += Check-Module -ModuleName "Visual Studio Installer" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe")
    }
    $modules += Check-Module -ModuleName "Visual Studio 2019 Community" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community")
    }
    $modules += Check-Module -ModuleName ".NET Core Tools Workload" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Microsoft\NetCoreTools")
    }
    $modules += Check-Module -ModuleName "Managed Desktop Workload" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Microsoft\ManagedDesktop")
    }
    $modules += Check-Module -ModuleName "ASP.NET & Web Development Workload" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Microsoft\NetWeb")
    }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -ne "OK") { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for VS2019: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# NuGet Tasks             #
###########################
function Check-NuGet {
    Write-Host "Status for NuGet CLI"
    $modules = @()

    $modules += Check-Module -ModuleName "NuGet CLI" -CheckScript {
        return (Test-Path "C:\ProgramData\chocolatey\bin\nuget.exe")
    }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -ne "OK") { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for NuGet: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# Visual Studio 2022 Tasks#
###########################
function Check-VS2022 {
    Write-Host "Status for Visual Studio 2022 Components"
    $modules = @()

    $modules += Check-Module -ModuleName "Visual Studio Installer" -CheckScript {
        return (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe")
    }
    $modules += Check-Module -ModuleName "Visual Studio 2022 Community" -CheckScript {
        return (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community")
    }
    $modules += Check-Module -ModuleName ".NET Core Tools Workload" -CheckScript {
        return (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\NetCoreTools")
    }
    if (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\ManagedDesktop") {
        $modules += @{ Name = "Managed Desktop Workload"; Status = "OK" }
    } else {
        $modules += @{ Name = "Managed Desktop Workload"; Status = "Skipped (to be implemented)" }
    }
    $modules += Check-Module -ModuleName "ASP.NET & Web Development Workload" -CheckScript {
        return (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\NetWeb")
    }
    $modules += Check-Module -ModuleName "Microsoft Web Deploy" -CheckScript {
        return (Test-Path "C:\Program Files\IIS\Microsoft Web Deploy V3")
    }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -notin @("OK", "Skipped (to be implemented)")) { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for VS2022: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# .NET Framework 3.5 Tasks#
###########################
function Check-DotNet35 {
    Write-Host "Status for .NET Framework 3.5 Components"
    $modules = @()

    $modules += Check-Module -ModuleName ".NET Framework 3.5" -CheckScript {
        return (Test-Path "C:\Windows\Microsoft.NET\Framework\v3.5")
    }
    $modules += @{ Name = "Microsoft Build Tools"; Status = "Skipped (to be implemented)" }

    $overallStatus = "OK"
    foreach ($m in $modules) {
        Write-Host " - $($m.Name) : $($m.Status)"
        if ($m.Status -notin @("OK", "Skipped (to be implemented)")) { $overallStatus = "Failed" }
    }
    Write-Host "Overall status for .NET 3.5: $overallStatus" -ForegroundColor Cyan
    Write-Host ""
    return $overallStatus
}

###########################
# Main Execution          #
###########################
Write-Host "Checking Build Machine Modules" -ForegroundColor Yellow
Write-Host "================================`n" -ForegroundColor Yellow

# Събиране на статусите от всяка секция
$statuses = @()
$statuses += Check-DotNet46
$statuses += Check-DotNet48
$statuses += Check-WiX
$statuses += Check-VS2019
$statuses += Check-NuGet
$statuses += Check-VS2022
$statuses += Check-DotNet35

# Определяне на финалния статус
if ($statuses -contains "Failed") {
    $finalStatus = "FAILED"
} else {
    $finalStatus = "OK"
}

Write-Host "FINAL RESULT: $finalStatus" -ForegroundColor Magenta

# Връщане на подходящ exit code за Jenkins:
if ($finalStatus -eq "FAILED") {
    exit 1
} else {
    exit 0
}
