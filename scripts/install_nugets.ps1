param (
    [string]$SolutionName = "ReconArtRelease.sln" # Default solution name
)

# Ensure the solution file exists
if (-Not (Test-Path $SolutionName)) {
    Write-Host "ERROR: Solution file '$SolutionName' does not exist in the current directory."
    exit 1
}

# Define the NuGet source and local packages directory
$nugetSource = "c:\temp\ReconArt.Nuget"
$packagesPath = Join-Path -Path (Get-Location) -ChildPath "packages"
$backupSource = "https://api.nuget.org/v3/index.json"

Write-Host "Checking NuGet dependencies for solution: $SolutionName"

# Define the packages and versions
$packages = @(
    @{ Name = "ReconArt.Core"; Version = "3.1.12.38256" },
    @{ Name = "ReconArt.Import.Engine"; Version = "3.3.0.38299" },
    @{ Name = "ReconArt.Core.Unity"; Version = "2.21.1.30889" },
    @{ Name = "ReconArt.Import.API.Parsers.Excel"; Version = "1.1.2" },
    @{ Name = "ReconArt.Import.API.Parsers.Csv"; Version = "1.0.5" },
    @{ Name = "ReconArt.Import.API.Parsers.Main"; Version = "2.0.0" },
    @{ Name = "ReconArt.Import.API.Parsers.FixedWidth"; Version = "1.0.5" },
    @{ Name = "ExcelDataReader"; Version = "3.7.0-develop00415" },
    @{ Name = "CsvHelper"; Version = "27.2.1" } # Примерна версия, проверете необходимата
)

# Loop through each package and check if it is installed
foreach ($package in $packages) {
    $packageFolder = Join-Path -Path $packagesPath -ChildPath "$($package.Name).$($package.Version)"
    $packageFileName = "$($package.Name).$($package.Version).nupkg"
    $packageFilePath = Join-Path -Path $nugetSource -ChildPath $packageFileName

    if (-Not (Test-Path $packageFolder)) {
        Write-Host "$($package.Name) version $($package.Version) not found in the local packages directory. Installing..."

        if (Test-Path $packageFilePath) {
            Write-Host "Found $packageFileName in $nugetSource. Installing..."
            nuget install $package.Name -Version $package.Version -Source $nugetSource -OutputDirectory $packagesPath
        } else {
            Write-Host "Package not found in $nugetSource. Attempting to download from public NuGet source..."
            nuget install $package.Name -Version $package.Version -Source $backupSource -OutputDirectory $packagesPath
        }

        # Restore dependencies after installing each package
        Write-Host "Restoring NuGet dependencies..."
        nuget restore $SolutionName -PackagesDirectory $packagesPath
    } else {
        Write-Host "$($package.Name) version $($package.Version) is already installed in $packagesPath."
    }
}


# Restore NuGet dependencies for the solution
Write-Host "Restoring NuGet packages for solution: $SolutionName"
nuget restore "$SolutionName" -PackagesDirectory $packagesPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: NuGet restore failed for $SolutionName. Check the solution and dependencies."
    exit 1
}

Write-Host "NuGet dependencies and solution restored successfully."

