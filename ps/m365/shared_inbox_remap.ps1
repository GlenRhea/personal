$TechName = Read-Host "Please enter your email address"
$EmployeeName = Read-Host "Please enter the email address of the employee who needs to be adjusted"
$SharedBox = Read-Host "Please enter the email address of the shared inbox that needs to be adjusted"

#If you haven't set up the new authentication method on your computer for Exchange online, please read the following and ensure the exo-v2 module is installed
#https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps
#https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#install-and-maintain-the-exo-v2-module

Import-Module ExchangeOnlineManagement

#Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName $TechName

#Remove Shared Inbox permissions
Remove-MailboxPermission -Identity $SharedBox -User $EmployeeName -AccessRights FullAccess

#Add Shared Inbox permissions without automapping privileges
Add-MailboxPermission -Identity $SharedBox -User $EmployeeName -AccessRights FullAccess -AutoMapping $false

Disconnect-ExchangeOnline