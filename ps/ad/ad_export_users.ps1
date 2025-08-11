function Output-Log {
    Param( 
           [Parameter(Mandatory)]
           [ValidateSet('info','warn', 'error')]
           [alias("L")] 
           [string]$LogLevel, 
    
           [alias("M")] 
           [string]$msg
       ) 
       $date = Get-Date
       #$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       $output = $date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       switch ($LogLevel) {
           warn { Write-Host -ForegroundColor Yellow $output}
           error { Write-Host -ForegroundColor Red $output}
           Default { Write-Host -ForegroundColor Green $output }
    }
}


Output-Log -L "info" -M "Starting the review of the onb_audit output files."
$exportFile = "C:\Temp\AD_Export.csv"
$data = @()
$users = Get-ADUser -Filter {Enabled -eq $true} -Properties GivenName, Surname, SamAccountName, UserPrincipalName, EmailAddress, DistinguishedName
 
foreach ($user in $users) {
    $ou = ($user.DistinguishedName -split ",", 2)[1]
 
    $data += [PSCustomObject]@{
        ObjectType        = "User"
        Name              = $user.Name
        SamAccountName    = $user.SamAccountName
        UserPrincipalName = $user.UserPrincipalName
        Email             = $user.EmailAddress
        OU                = $ou
        GroupName         = ""
    }
}
 
$groups = Get-ADGroup -Filter * -Properties DistinguishedName
 
foreach ($group in $groups) {
    $groupOU = ($group.DistinguishedName -split ",", 2)[1]
 
    $members = Get-ADGroupMember -Identity $group | Where-Object { 
        $_.objectClass -eq "user" -and (Get-ADUser $_.DistinguishedName -Properties Enabled).Enabled -eq $true 
    }
 
    foreach ($member in $members) {
        $data += [PSCustomObject]@{
            ObjectType        = "GroupMember"
            Name              = $member.Name
            SamAccountName    = $member.SamAccountName
            UserPrincipalName = $member.DistinguishedName
            Email             = ""
            OU                = $groupOU
            GroupName         = $group.Name
        }
    }
}
 
$data | Export-Csv -Path $exportFile -NoTypeInformation -Encoding UTF8
