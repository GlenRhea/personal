#checks for passwords that expire on the current day and emails IT about it

#needed for the Send-MailMessage cmdlet
$PSEmailServer = "smtpserver.company.local"

#globals
$users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "EmailAddress", "msDS-UserPasswordExpiryTimeComputed"|Select-Object -Property "Displayname","EmailAddress",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
$now = get-date
$sendemail = $false
#only needed if the script hasn't been run yet
#New-EventLog –LogName Application –Source “PasswordExiryScript”
$body = "These user's passwords are expiring today!<br><br>"

#get script name
$scriptname = $MyInvocation.MyCommand.Name 

foreach ($user in $users) {
	#check to see if their password expires today
	#if ($true) 
	#if ($user.EmailAddress -eq "user@company.com")
 	if (($now.Day -eq $user.ExpiryDate.Day) -and ($now.Month -eq $user.ExpiryDate.Month)) 		
 	{
		#$message = $user.DisplayName + "'s password expires today! (" + $user.ExpiryDate + ")"
		$message = $user.DisplayName + " (" + $user.EmailAddress + ")" + "'s password expires today! (" + $user.ExpiryDate + ")"
		#email the user 
		$userbody = "Dear " + $user.DisplayName + "<br>Your password expires today @ " + $user.ExpiryDate + 
			".<br> To change your password, hit ctrl alt delete at the same time and select Change a password." +
			"<br> If you do not change your password you will not be able to access anything in the office!"
		Send-MailMessage -From "smtpuser@company.com" -To $user.EmailAddress -Subject "*** Expiring Password Notification ***" -Body $userbody -bah -Priority "High"
		
		#add event log entry
		write-host $message
		write-eventlog -logname Application -source "PasswordExiryScript" -eventID 1001 -entrytype Information -message $message -category 1 -rawdata 10,20
		
		#append to email body
		$body = $body + $message + "<br>"
		$sendemail = $true
	}
}

if ($sendemail) {
	#send email 
	Send-MailMessage -From "smtpuser@company.com" -To "IT@company.com" -Subject "*** Expiring Password Notification ***" -Body $body -bah -Priority "High"
}