# 1. Check if the script is running with Administrator privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-Not $IsAdmin) {
    Write-Host "Error: The script is not running with administrator privileges. Please run as Administrator."
    exit
} else {
    Write-Host "Running with administrator privileges. Proceeding with the script."
}

# 2. Check if the user 'Administrator' exists
Write-Host "Checking if user 'Administrator' exists..."

$user = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue

if ($null -eq $user) {
    Write-Host "Error: The user 'Administrator' does not exist. Exiting script."
    exit
} else {
    Write-Host "User 'Administrator' exists. Proceeding with the script."
}

# 3. Enable OpenSSH Windows feature
Write-Host "Enabling OpenSSH feature..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 4. Create the .ssh directory for the user 'Administrator' if it doesn't exist
$sshDir = "C:\Users\Administrator\.ssh"
if (-Not (Test-Path $sshDir)) {
    Write-Host "Creating .ssh directory for 'Administrator'..."
    New-Item -ItemType Directory -Force -Path $sshDir
}

# 5. Create authorized_keys file for 'Administrator'
$authorizedKeysPath = "C:\Users\Administrator\.ssh\authorized_keys"
Write-Host "Creating authorized_keys for 'Administrator'..."
New-Item -ItemType File -Force -Path $authorizedKeysPath

# 6. Add the SSH public key to 'Administrator' authorized_keys
$publicKey = "your-ssh-public-key-here"  # Replace with your actual SSH public key
Add-Content -Path $authorizedKeysPath -Value $publicKey
Write-Host "Public key added to authorized_keys for 'Administrator'."

# 7. Create the administrators_authorized_keys file in ProgramData\ssh
$adminAuthorizedKeysPath = "C:\ProgramData\ssh\administrators_authorized_keys"
Write-Host "Creating administrators_authorized_keys..."
New-Item -ItemType File -Force -Path $adminAuthorizedKeysPath

# 8. Add the SSH public key to the administrators_authorized_keys
Add-Content -Path $adminAuthorizedKeysPath -Value $publicKey
Write-Host "Public key added to administrators_authorized_keys."

# 9. Install Chocolatey (if not installed)
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed."
} else {
    Write-Host "Chocolatey is already installed."
}

# 10. Install Python using Chocolatey
Write-Host "Installing Python using Chocolatey..."
choco install python --yes

# 11. Verify the Python installation
Write-Host "Verifying Python installation..."
$pythonVersion = python --version
Write-Host "Python version: $pythonVersion"

# 12. Allow access for administrators to authorized_keys file
Write-Host "Setting permissions for administrators on administrators_authorized_keys..."
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:(F)"

# 13. Allow access for the 'Administrator' user to authorized_keys file
Write-Host "Setting permissions for 'Administrator' on authorized_keys..."
icacls "C:\Users\Administrator\.ssh\authorized_keys" /grant "Administrator:(F)"

# 14. Adds bootstrap's public key
$Key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvKFdjg3v+tLNL1RTP/WVVWLZStrJ5d0GYO7Z04Igc+dkYVryD20HPudXUs3i1w8fgnS0wj6S+b7tm3/RIz/iEBiXD2zA+/ETfPQANXxluTuPJQKkQ/eIhoZ7Q2ZI8OvuxUCk/7txEY2Uttif/+tTNoGb2hIFo6b8tu9Au+IC303L3yFXovUq6THHIh5pd70pPpTeUlg/55kuRYND0zBaTxgSG++TFoF4yFhmvG3VRT99ibY4CNJOwlLWcxXO6CKQ55QzjpbsG7KC/4GQJUbc82ZscROJFQAs4rPiH9kh1M062W1drE017bCtjmLvgqGdN8IRPRpgKH9fqD4P0IWzWxJUgXpLy1woZndY5lYOkj9p67K1XLIXlhi8+LScy16Iv05ZVPSdXNrIfflzUyUifXuHS/pe3KPUs69FxVEXsaFJlBnPHVD98/UQ1vo5vwMD3cLlNh4KeWJDpvnld1BZ553U+CZ44JBgLFggP0avD4D4ypU7+RqQrcLH3uwUb1JU= bootstrap"

# 14.1. Add to c:\programdata\ssh\administrators_authorized_keys
$Path1 = "C:\ProgramData\ssh\administrators_authorized_keys"
New-Item -ItemType File -Force -Path $Path1 | Out-Null
Add-Content -Path $Path1 -Value $Key

# 14.2. Add to c:\users\administrator\.ssh\authorized_keys
$Path2 = "C:\Users\Administrator\.ssh\authorized_keys"
New-Item -ItemType File -Force -Path $Path2 | Out-Null
Add-Content -Path $Path2 -Value $Key

# 15. Fix access rights to the file AND to the directory
# Ensure proper permissions for the SSH directory and authorized keys file
$sshDirectory = "C:\ProgramData\ssh"
$authorizedKeysFile = "$sshDirectory\administrators_authorized_keys"

# Ensure the SSH directory exists
if (-Not (Test-Path $sshDirectory)) {
    New-Item -ItemType Directory -Path $sshDirectory -Force
}

# Set correct permissions for the SSH directory
icacls $sshDirectory /inheritance:r # Remove inherited permissions
icacls $sshDirectory /grant:r "Administrators:F" "System:F" # Grant full access to Administrators and System

# Ensure the authorized keys file exists (create an empty file if it does not exist)
if (-Not (Test-Path $authorizedKeysFile)) {
    New-Item -ItemType File -Path $authorizedKeysFile -Force
}

# Set correct permissions for the authorized keys file
icacls $authorizedKeysFile /inheritance:r # Remove inherited permissions
icacls $authorizedKeysFile /grant:r "Administrators:F" "System:F" # Grant full access to Administrators and System

# Restart the SSH service to apply changes
Restart-Service sshd


# 16. Allow ping from outside
Write-Host "Allow machine to be ping from outside..."
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow

# 17. Set powershell as a default shell in the registry
# Define the registry path and key
$registryPath = "HKLM:\SOFTWARE\OpenSSH"
$registryKey = "DefaultShell"
$defaultShellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

# Check if the registry path exists, create it if necessary
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

# Set the DefaultShell registry key
Set-ItemProperty -Path $registryPath -Name $registryKey -Value $defaultShellPath

# Confirm the change
Write-Host "DefaultShell registry key set to:" (Get-ItemProperty -Path $registryPath -Name $registryKey).DefaultShell

# Restart the sshd service to apply changes
Restart-Service sshd

Write-Host "sshd service restarted. DefaultShell configuration applied."

# 18. Creating Ansible Temp directory
# Define the path
$path = "C:\ansible_temp"

# Check if the directory exists, create it if not
if (-not (Test-Path -Path $path)) {
    New-Item -ItemType Directory -Path $path -Force
    Write-Host "Directory created: $path"
} else {
    Write-Host "Directory already exists: $path"
}


Write-Host "Script completed successfully."


