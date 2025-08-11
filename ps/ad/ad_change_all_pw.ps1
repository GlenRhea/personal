$users = Get-ADUser -Filter 'enabled -eq $true'

foreach ($user in $users) {
    $user = $user.SamAccountName
    Set-ADAccountPassword -Identity $user -NewPassword (ConvertTo-SecureString -AsPlainText "Password1" -Force)
    Set-ADUser -Identity $user -ChangePasswordAtLogon $true
}

#now set the intelecom account back
$user = Get-ADUser -Identity "intelecom"
Set-ADAccountPassword -Identity $user -NewPassword (ConvertTo-SecureString -AsPlainText "F,onW?_^Y/ob[jAa{z|*EGC/-yv@0T=p" -Force)
