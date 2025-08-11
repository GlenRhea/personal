#this script will get you a list of all active users in AD that haven't logged in for 30 days
$today = (Get-Date).AddDays(-30) 
$result = Get-ADUser -Filter {LastLogonDate -lt $today -and Enabled -eq $true} -Properties LastLogonDate | Select-Object SamAccountName, LastLogonDate
$result | Export-Csv -Path ".\active_users_norecentlogin.csv" -NoTypeInformation -Encoding UTF8 -Force
