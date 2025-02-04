# Start-Agent.ps1
schtasks /run /tn "Start Jenkins Swarm Agent"
Write-Host "Agent started. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

