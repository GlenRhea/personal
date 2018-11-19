#reference: https://goo.gl/ocdQeB

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber

#get the mbox plan name
Get-CASMailboxPlan | fl Name

#take the name for the EOEnterprise and substitute
Set-CASMailboxPlan $ENTERNAMEHEREFROMABOVE -ImapEnabled $false -PopEnabled $false

Remove-PSSession $Session

