# update_known_hosts.ps1
# This script updates the known_hosts file for the agent user.
# It preserves existing entries (excluding any lines containing "bitbucket.reconart.net" or "github.com"),
# then appends the updated keys for Bitbucket (using RSA on port 7999) and GitHub (using ECDSA).
#
# Note: The script filters out any comment lines (lines starting with "#") from the ssh-keyscan output.

# Define the path to the known_hosts file using the current user's username
$file = "C:\Users\$env:USERNAME\.ssh\known_hosts"

# If the known_hosts file exists, filter out lines containing "bitbucket.reconart.net" and "github.com"
if (Test-Path $file) {
    $existing = Get-Content $file | Where-Object { $_ -notmatch "bitbucket\.reconart\.net" -and $_ -notmatch "github\.com" }
} else {
    $existing = @()
}

# Retrieve the Bitbucket key via ssh-keyscan (RSA on port 7999)
# Filter out any lines starting with '#' and select the first valid line.
$bitbucket = ssh-keyscan -t rsa -p 7999 bitbucket.reconart.net | Where-Object { $_ -notmatch '^#' } | Select-Object -First 1

# Retrieve the GitHub key via ssh-keyscan (ECDSA)
# Filter out any lines starting with '#' and select the first valid line.
$github = ssh-keyscan -t ecdsa github.com | Where-Object { $_ -notmatch '^#' } | Select-Object -First 1

# (Optional) Write the retrieved keys to the host console for debugging.
Write-Host "Bitbucket key:" $bitbucket
Write-Host "GitHub key:" $github

# Combine the existing entries with the new keys
$newContent = $existing + $bitbucket + $github

# Write the combined content back to the known_hosts file with Windows line breaks.
Set-Content -Path $file -Value ($newContent -join "`r`n") -Encoding UTF8 -Force

