#get non-expiring passwords
Search-ADAccount -PasswordNeverExpires -UsersOnly -ResultPageSize 2000 -resultSetSize $null | Select-Object Name, SamAccountName, DistinguishedName

#| Export-CSV “C:\Temp\PassNeverExpiresUsers.CSV” -NoTypeInformation