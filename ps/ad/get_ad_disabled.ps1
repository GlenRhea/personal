#get disabled accounts
Search-ADAccount -AccountDisabled
#or
Get-ADUser -Filter {Enabled -eq $false} | FT samAccountName

#this gets inactive users
Search-ADAccount –AccountInActive –TimeSpan 90:00:00:00 –ResultPageSize 2000 –ResultSetSize $null | ?{$_.Enabled –eq $True} | Select-Object Name, SamAccountName, DistinguishedName | sort-object Name
#| Export-CSV “C:\Temp\InActiveUsers.CSV” –NoTypeInformation