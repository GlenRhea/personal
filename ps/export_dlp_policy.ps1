$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

$file = Export-DlpPolicyCollection
Set-Content -Path "C:\temp\company.xml" -Value $file.FileData -Encoding Byte

Remove-PSSession $Session