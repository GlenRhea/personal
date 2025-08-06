#Requires -Modules NTFSSecurity
#Requires -RunAsAdministrator
#,ActiveDirectory
#Clear-Host

#todo

#references
#https://www.techtarget.com/searchwindowsserver/tutorial/Reveal-Windows-file-server-permissions-with-PowerShells-help

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\fs"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the FS script!"
Output-Log info "FS - All reports will be here: $outputPath"



Try {
    if (Test-Path $outputPath) {

        #now get all the file shares
        Output-Log info "FS - Getting all file shares"
        $shares = Get-SmbShare
        $shares | Export-Csv -Path  "$outputPath\all_shares.csv" -NoTypeInformation -Encoding UTF8 -Force

        #now get all the file share permissions
        Output-Log info "FS - Getting all file share permissions"
        foreach ($share in $shares) {
            $shareName = $share.Name
            $fspath = $share.Path
            if ($shareName -notmatch "\$") {
                #since we're already pulling the share names, let's loop through those
                Output-Log info "`tWorking on $shareName"
                $shareperms = Get-SmbShareAccess -Name $shareName
                $filename = "$shareName-share_permissions.csv"
                $shareperms | Export-Csv -Path  "$outputPath\$filename" -NoTypeInformation -Encoding UTF8 -Force

                #list blocked inheritance
                Output-Log info "FS - Checking for blocked inheritance"
                $allFolders =  Get-ChildItem -Path $fspath -Directory -Recurse  -ErrorAction SilentlyContinue 
                $notInherited = $allFolders | Get-NTFSAccess | Where-Object {!($_.InheritanceEnabled)}
                $notInherited | Export-Csv -Path "$outputPath\$shareName-fs_blocked_inheritance.csv" -NoTypeInformation -Encoding UTF8 -Force
                
                #check for user permissions vs groups
                <# foreach ($folder in $allFolders) {
                    #$folder.FullName
                    $folder = $folder.FullName
                    $acl = Get-Acl $folder

                    # Check permissions for each identity (user or group)
                    foreach ($accessRule in $acl.Access) {
                        $identity = $accessRule.IdentityReference
                        $permissions = $accessRule.FileSystemRights
                        $identity.GetType().Name
                        # Check if the identity is a group
                        if ($identity.GetType().Name -eq "NTAccount") {
                            #$isGroup = $identity.Value.Contains("\")
                            $UPN = $($identity.Value)
                            $UPN = $UPN.split('\')
                            $UPN = $UPN[1]
                            $Group = Get-ADGroup -LDAPFilter "(SAMAccountName=$UPN)"
                            if ($Group) {$isGroup = $true} else {$isGroup = $false}
                            $isGroup
                        } else {
                            $isGroup = $false
                            #Write-Output "Identity: $($identity.Value)"
                        }

                        Write-Output "Identity: $($identity.Value)"
                        Write-Output "Is Group: $isGroup"
                        Write-Output "Permissions: $permissions"
                        Write-Output "-------------------------"
                    }
                }    #>             

                #find file paths that are too long
                Output-Log info "FS - Checking for file paths that are too long"
                #there was no pure PS way of doing this unfortunately :(
                cmd /c "cd /d $fspath && dir /b /s /a" | ForEach-Object { if ($_.length -gt 250) {$_ | Out-File -append "$outputPath\$shareName-long_file_paths.txt"}}
            }
            
        }
        
        

        } else {
            Output-Log -L "error" -M "Please enter a valid path!"
        }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
