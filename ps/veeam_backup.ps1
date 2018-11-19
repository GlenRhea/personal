#this script backs up our vms

#Requires -RunAsAdministrator
#Requires -PSSnapin  VeeamPSSnapin

function Output-Log {
 Param( 
        [alias("L")] 
        [string]$LogLevel, 
 
        [alias("M")] 
        [string]$msg
    ) 
	$date = Get-Date
	$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
}

Try {
	#enable the snapin
	Add-PSSnapin VeeamPSSnapin

	#connect to the server
	Connect-VBRServer

	#start the backup
	#maybe put an array with the VM names here for backups and then loop through them
	#vms to backup:
		$servers = @("vcenter")
	# maybe do full backups only on weekends since it will take so long?

	#Start-VBRZip -Folder "E:\Backup\Veeam" -Entity $vm -Compression 5 -DisableQuiesce -RunAsync -AutoDelete in3Days
	foreach ($server in $servers) {
		$vm = Find-VBRViEntity -Name "$server"
		Output-Log -L "INFO" -M "Backing up: $server = " + $vm.Id
		Start-VBRZip -Folder "X:\Backup\VeeamBackup" -Entity $vm -Compression 5 -DisableQuiesce -AutoDelete In1Month
	 }

	#powershell send email
	$PSEmailServer = "smtpserver.company.local"
	Send-MailMessage -From "smtpuser@company.com" -To "user@company.com" -Subject "VM Backups Completed" -Body "VM Backups Completed"

	#disconnect
	Disconnect-VBRServer

	#disable the snapin
	Remove-PSSnapin VeeamPSSnapin
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "The backup job failed. The error is: $ErrorMessage"
	Send-MailMessage -From "smtpuser@company.com" -To "user@company.com" -Subject "VM Backups ERROR!!" -Body "The backup job failed. The error is: $ErrorMessage"
	Exit 1
}