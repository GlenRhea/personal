Import-Module ActiveDirectory

$groups = Get-ADGroup -Filter * -SearchBase "OU=Security Groups,DC=company,DC=local" #| Select-Object SamAccountName

foreach ($group in $groups) {
    $name = $group.Name
    $members = Get-ADGroupMember -Identity "$name" -Recursive
    foreach ($member in $members) {
        $memberName = $member.Name
        Write-Output $name","$memberName
    }
}
