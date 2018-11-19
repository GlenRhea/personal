$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

#set to be abel to see calendar details
Set-MailboxFolderPermission -Identity conferenceroom1@company.com:\calendar -User default -AccessRights LimitedDetails
Set-MailboxFolderPermission -Identity conferenceroom2@company.com:\calendar -User default -AccessRights LimitedDetails
Set-MailboxFolderPermission -Identity conferenceroom3@company.com:\calendar -User default -AccessRights LimitedDetails

#set to show only the subject
Set-CalendarProcessing -Identity conferenceroom1@company.com -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false
Set-CalendarProcessing -Identity conferenceroom2@company.com -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false
Set-CalendarProcessing -Identity conferenceroom3@company.com -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false