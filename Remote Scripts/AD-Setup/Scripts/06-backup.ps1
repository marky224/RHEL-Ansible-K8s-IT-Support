# Purpose: Configures system state backup
Install-WindowsFeature -Name Windows-Server-Backup

# Run initial backup
wbadmin start systemstatebackup -backupTarget:E:

# Schedule daily backup (example using Task Scheduler)
$action = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start systemstatebackup -backupTarget:E: -quiet"
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
Register-ScheduledTask -TaskName "DailyADBackup" -Action $action -Trigger $trigger -Description "Daily AD system state backup"
