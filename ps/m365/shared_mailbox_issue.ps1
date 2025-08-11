$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

Remove-MailboxPermission sharedmbox -User user -AccessRights FullAccess

Add-MailboxPermission sharedmbox -User user -AccessRights FullAccess -AutoMapping $false