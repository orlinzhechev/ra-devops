# Stop-Agent.ps1
schtasks /end /tn "Start Jenkins Swarm Agent"
Write-Host "Agent stopped. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

