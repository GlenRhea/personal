#powershell template script
# if you have any requires!
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory
#Requires -Modules NTFSSecurity
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
	#source another ps script
	. ./NewPassword.ps1
	$pw = New-Password -length 18 -U -L -N -S
	Output-Log -L "info" -M "The password has been generated and will be saved in KeePass."
	Output-Log -L "info" -M "The password is ""$pw"" (between the first and last double quotes!)"
	
	#get ps version
	$PSVersionTable.PSVersion
	
	#pause
	Read-Host -Prompt "Press Enter to continue..."
	
	#powershell send email
	$PSEmailServer = "smtpserver.company.local"
	Send-MailMessage -From "smtpuser@company.com" -To "user@company.com" -Subject "VM Backups Completed" -Body "VM Backups Completed"
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "The password generating code could not be loaded. The error is: $ErrorMessage"
	Exit 1
}