# 1. Check if the script is running with Administrator privileges
$IsAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdmin.HasElevatedPrivileges

if (-Not $IsAdmin.HasElevatedPrivileges) {
    Write-Host "Error: The script is not running with administrator privileges. Please run as Administrator."
    exit
} else {
    Write-Host "Running with administrator privileges. Proceeding with the script."
}

# 2. Check if the user 'bootstrap' exists
Write-Host "Checking if user 'bootstrap' exists..."

$user = Get-LocalUser -Name "bootstrap" -ErrorAction SilentlyContinue

if ($null -eq $user) {
    Write-Host "Error: The user 'bootstrap' does not exist. Exiting script."
    exit
} else {
    Write-Host "User 'bootstrap' exists. Proceeding with the script."
}

# 3. Create the .ssh directory for the user 'bootstrap' if it doesn't exist
$sshDir = "C:\Users\bootstrap\.ssh"
if (-Not (Test-Path $sshDir)) {
    Write-Host "Creating .ssh directory for 'bootstrap'..."
    New-Item -ItemType Directory -Force -Path $sshDir
}

# 4. Create authorized_keys file for 'bootstrap'
$authorizedKeysPath = "C:\Users\bootstrap\.ssh\authorized_keys"
Write-Host "Creating authorized_keys for 'bootstrap'..."
New-Item -ItemType File -Force -Path $authorizedKeysPath

# 5. Add the SSH public key to 'bootstrap' authorized_keys
$publicKey = "your-ssh-public-key-here"  # Replace with your actual SSH public key
Add-Content -Path $authorizedKeysPath -Value $publicKey
Write-Host "Public key added to authorized_keys for 'bootstrap'."

# 6. Create the administrators_authorized_keys file in ProgramData\ssh
$adminAuthorizedKeysPath = "C:\ProgramData\ssh\administrators_authorized_keys"
Write-Host "Creating administrators_authorized_keys..."
New-Item -ItemType File -Force -Path $adminAuthorizedKeysPath

# 7. Add the SSH public key to the administrators_authorized_keys
Add-Content -Path $adminAuthorizedKeysPath -Value $publicKey
Write-Host "Public key added to administrators_authorized_keys."

# 8. Install Chocolatey (if not installed)
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed."
} else {
    Write-Host "Chocolatey is already installed."
}

# 9. Install Python using Chocolatey
Write-Host "Installing Python using Chocolatey..."
choco install python --yes

# 10. Verify the Python installation
Write-Host "Verifying Python installation..."
$pythonVersion = python --version
Write-Host "Python version: $pythonVersion"

# 11. Allow access for administrators to authorized_keys file
Write-Host "Setting permissions for administrators on administrators_authorized_keys..."
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:(F)"

# 12. Allow access for the 'bootstrap' user to authorized_keys file
Write-Host "Setting permissions for 'bootstrap' on authorized_keys..."
icacls "C:\Users\bootstrap\.ssh\authorized_keys" /grant "bootstrap:(F)"

Write-Host "Script completed successfully."

