$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

Search-Mailbox -Identity "First Username"   -TargetMailbox "Second Username"  -TargetFolder   "accountname" -LogLevel Full

Remove-PSSession $Session