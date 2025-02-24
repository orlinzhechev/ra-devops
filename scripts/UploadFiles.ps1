param(
    [string]$user = "jenkins",  # Artifactory username
    [string]$pass,            # API token (password) for authentication
    [string]$sourceDir = "\\bg-pld-nas001\ReconArt.Nuget",  # Source directory (default value)
    [string]$destURL = "https://artifactory.reconart.net:443/artifactory/generic-reconart-nuget/",  # Destination URL
    [switch]$Recurse,         # Enable recursive file search
    [switch]$force,           # Force upload without checking if file exists at destination
    [switch]$wipeDestinationDir,  # Delete all files in destination directory before uploading
    [switch]$DryRun,          # DryRun mode: only display status without uploading
    [int]$limit = 0,          # Limit the maximum number of files to synchronize; 0 means no limit
    [string[]]$exclude       # Exclude files matching these wildcard patterns (e.g. "*.zip" or "cmd*.zip ext*.zip")
)

# Process exclude patterns: if provided as a single string with spaces, split them.
if ($exclude) {
    if ($exclude -is [string]) {
        $excludePatterns = $exclude.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    }
    else {
        $excludePatterns = $exclude
    }
}
else {
    $excludePatterns = @()
}

# Check if the API token is provided
if (-not $pass) {
    Write-Error "Please provide the API token using the -pass parameter."
    exit 1
}

# Resolve the source directory using ProviderPath for UNC paths
try {
    $resolvedSourceDir = (Resolve-Path $sourceDir).ProviderPath
} catch {
    Write-Error "Source directory '$sourceDir' cannot be resolved."
    exit 1
}
# Ensure the resolved source directory ends with a backslash
if (-not $resolvedSourceDir.EndsWith("\")) {
    $resolvedSourceDir += "\"
}

# Ensure the destination URL ends with a slash
if (-not $destURL.EndsWith("/")) {
    $destURL += "/"
}

# Build the header for API authentication
$headers = @{
    "X-JFrog-Art-Api" = $pass
}

# If wipeDestinationDir is set, prompt for confirmation and then delete the destination directory contents
if ($wipeDestinationDir) {
    $confirmation = Read-Host "Are you sure you want to wipe the destination directory $destURL? Type 'yes' to confirm"
    if ($confirmation -eq "yes") {
        try {
            Write-Host "Wiping destination directory $destURL..."
            Invoke-RestMethod -Uri $destURL -Method Delete -Headers $headers
            Write-Host "Destination directory wiped successfully."
        }
        catch {
            Write-Error "Error wiping destination directory: $($_)"
            exit 1
        }
    }
    else {
        Write-Host "Wipe destination directory cancelled by user."
        exit 0
    }
}

# Retrieve files from the resolved source directory (recursively if -Recurse is specified)
if ($Recurse) {
    $files = Get-ChildItem -Path $resolvedSourceDir -Recurse -File
} else {
    $files = Get-ChildItem -Path $resolvedSourceDir -File
}

if ($files.Count -eq 0) {
    Write-Host "No files found in $resolvedSourceDir."
    exit 0
}

# Counter for processed (non-excluded) files
$processedCount = 0

foreach ($file in $files) {
    $filePath = $file.FullName

    # Check if the full file path starts with the resolved source directory before extracting the relative path
    if ($filePath.StartsWith($resolvedSourceDir)) {
        $relativePath = $filePath.Substring($resolvedSourceDir.Length)
    }
    else {
        Write-Warning "File path '$filePath' does not start with resolved source directory '$resolvedSourceDir'. Using file name instead."
        $relativePath = $file.Name
    }
    # Replace backslashes with forward slashes for URL compatibility
    $relativePath = $relativePath -replace '\\', '/'

    # Construct the complete upload URL preserving the subdirectory structure
    $uploadUrl = $destURL + $relativePath

    # Check for exclude patterns based on the file name
    $isExcluded = $false
    foreach ($pattern in $excludePatterns) {
        if ($file.Name -like $pattern) {
            Write-Host "Excluded: $relativePath ($uploadUrl)"
            $isExcluded = $true
            break
        }
    }
    if ($isExcluded) { continue }

    # Increment the counter for processed files
    $processedCount++
    # If limit is set and reached, exit the loop
    if ($limit -gt 0 -and $processedCount -gt $limit) { break }

    if ($DryRun) {
        # In DryRun mode, check file status and display target name and path without uploading
        try {
            $response = Invoke-WebRequest -Uri $uploadUrl -Method Head -Headers $headers -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $remoteSize = $response.Headers["Content-Length"]
                if ($remoteSize -and [long]$remoteSize -eq $file.Length) {
                    $status = "OK"
                }
                else {
                    $status = "Differ"
                }
            }
        }
        catch {
            $status = "Missing"
        }
        Write-Host "DryRun: ${status}: $relativePath ($uploadUrl)"
    }
    else {
        $uploadFile = $true

        if (-not $force) {
            try {
                $response = Invoke-WebRequest -Uri $uploadUrl -Method Head -Headers $headers -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    $remoteSize = $response.Headers["Content-Length"]
                    if ($remoteSize -and [long]$remoteSize -eq $file.Length) {
                        $status = "OK"
                        Write-Host "${status}: $relativePath ($uploadUrl)"
                        $uploadFile = $false
                    }
                    else {
                        $status = "Differ"
                        Write-Host "${status}: $relativePath ($uploadUrl)"
                    }
                }
            }
            catch {
                $status = "Missing"
                Write-Host "${status}: $relativePath ($uploadUrl)"
            }
        }
        else {
            # If force is set, bypass HEAD check
            $status = "Force"
            Write-Host "${status}: $relativePath ($uploadUrl)"
        }

        if ($uploadFile) {
            Write-Host "Uploading $relativePath to $uploadUrl..."
            try {
                # Calculate checksums for the file
                $hashMD5 = Get-FileHash -Path $filePath -Algorithm MD5
                $hashSHA1 = Get-FileHash -Path $filePath -Algorithm SHA1
                $hashSHA256 = Get-FileHash -Path $filePath -Algorithm SHA256

                # Create a new headers hashtable including the original headers and checksum headers
                $fileHeaders = @{}
                foreach ($key in $headers.Keys) {
                    $fileHeaders[$key] = $headers[$key]
                }
                $fileHeaders["X-Checksum-Md5"] = $hashMD5.Hash.ToLower()
                $fileHeaders["X-Checksum-Sha1"] = $hashSHA1.Hash.ToLower()
                $fileHeaders["X-Checksum-Sha256"] = $hashSHA256.Hash.ToLower()

                Invoke-RestMethod -Uri $uploadUrl -Method Put -InFile $filePath -Headers $fileHeaders
                Write-Host "File $relativePath uploaded successfully."
            }
            catch {
                Write-Error "Error uploading ${relativePath}: $($_)"
            }
        }
    }
}

