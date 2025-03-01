# Helper functions
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message" | Out-File -FilePath "C:\ADSetup.log" -Append
}
Export-ModuleMember -Function Write-Log
