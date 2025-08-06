Clear-Host

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

function Build-HtmlList($data) {
    "<ul>" +
    ($data | ForEach-Object {
        "<li>" + $_.Name + 
        $(if ($_.Children) {
            Build-HtmlList $_.Children 
        }) + 
        "</li>"
    }) +
    "</ul>"
}

$workingDir = "C:\temp\onb_audit"
#disable the progress bars
$ProgressPreference = 'SilentlyContinue'
#for the "client health indicator"
$errorCount = 0
$warningCount = 0

#let's do html output so we can copy/paste it into hudu
$report = "$workingDir\report.html"
#this will be the main report with the subsections being added from the hashtables below
$reportBody = ""
#now let's create sections
$modules_ad = @{}
$modules_bpa = @{}
$modules_dns = @{}
$modules_fs = @{}
$modules_sys = @{}

try {
    Output-Log -L "info" -M "Starting the review of the onb_audit output files."
    
    Output-Log -L "info" -M "Cleaning out the old staging files."
    Remove-Item -Path "$workingDir\staging\*" -Force -Recurse -Confirm:$false

    Output-Log -L "info" -M "Unzipping onb_audit output files."
    $files = Get-ChildItem "$workingDir\zips\*.zip"
    foreach ($file in $files) {
        Output-Log -L "info" -M "Working on $file."
        #create the folder for the zip file to go into
        $folder = $file.BaseName
        $fileName = $file.Name
        New-Item -Path "$workingDir\staging\$folder" -ItemType Directory -Force > $null
        $ProgressPreference = 'SilentlyContinue'
        Expand-Archive -Path "$workingDir\zips\$fileName" -DestinationPath "$workingDir\staging\$folder" -Force
    }
    Output-Log -L "info" -M "All files have been Unzipped."
    #lets just pull the list of csv files
    $files = Get-ChildItem "$workingDir\staging" -Recurse -File -Include *.csv
    foreach ($file in $files) {
        Output-Log -L "info" -M "Working on the output in file $file."
        $path = $file.FullName
        $server = $path.Split('\')
        $server = $server[4].Split("_")
        $server = $server[0]
        $fileName = $file.BaseName
        $importedFile = Import-Csv -Path $path
        #check for empty files since not all of them have output
        $count = $importedFile.Count
        if ($count -gt 0) {
            #let's start with the bpa output since they're standardized
            #bpa
            if ($path -match "bpa") {
                foreach ($row in $importedFile) {
                    $severity = $row.Severity
                    $title = $row.Title
                    #if we want to output them
                    #$problem = $row.Problem
                    #$impact = $row.Impact
                    #$resolution = $row.Resolution
                    switch ($severity) {
                        "Warning" { 
                            Output-Log -L "warn" -M "`tBPA - $title" 
                            #$modules_bpa.Add($server,$title)
                            $warningCount++
                        }
                        "Error" { 
                            Output-Log -L "error" -M "`tBPA - $title" 
                            #$modules_bpa.Add($server,$title)
                            $errorCount++
                        }
                        Default {}
                    }
                }
            }
            #dns
            if ($path -match "dns") {
                if (($fileName -eq "mxrecords") -and ($count -gt 3)) {
                    Output-Log -L "error" -M "`tDNS - There are more than 2 MX records!"
                    $modules_dns.Add($server,"There are more than 2 MX records!")
                    $errorCount++
                }
                if ($fileName -eq "spfdkimdmarc") {
                    #Output-Log -L "error" -M "`tDNS - There are more than 2 MX records!"
                    foreach ($row in $importedFile) {
                        $domain = $row.Name
                        $SpfAdvisory = $row.SpfAdvisory
                        $DmarcAdvisory = $row.DmarcAdvisory
                        $DkimAdvisory = $row.DkimAdvisory
                        #spf
                        if ($SpfAdvisory -ne "An SPF-record is configured and the policy is sufficiently strict.") {
                            Output-Log -L "error" -M "`tDNS - $domain - $SpfAdvisory"
                            #$modules_dns.Add($server,$SpfAdvisory)
                            $errorCount++
                        }
                        #dmarc
                        if ($DmarcAdvisory -ne "Domain has a DMARC record and your DMARC policy will prevent abuse of your domain by phishers and spammers.") {
                            Output-Log -L "error" -M "`tDNS - $domain -  $DmarcAdvisory"
                            #$modules_dns.Add($server,$DmarcAdvisory)
                            $errorCount++
                        }
                        #dkim
                        if ($DkimAdvisory -ne "DKIM-record found.") {
                            Output-Log -L "error" -M "`tDNS - $domain - $DkimAdvisory"
                            #$modules_dns.Add($server,$DkimAdvisory)
                            $errorCount++
                        }
                    }
                }                
            }
            #sysadmin
            if ($path -match "sysadmin") {
                if ($fileName -eq "disk_unallocated_space") {
                    Output-Log -L "error" -M "`tSYS - There are raw disks!"
                    $errorCount++
                }
                if ($fileName -eq "network_firewall_status") {
                    foreach ($row in $importedFile) {
                        $enabled = $row.Enabled
                        $fwprofile = $row.Profile
                        if($enabled -eq "False") {
                            Output-Log -L "error" -M "`tSYS - The firewall profile $fwprofile is disabled!"
                            $errorCount++
                        }
                    }
                }
                #let's go ahead and import all the info from the server in case it isn't in RMM yet
                <# $content = Get-Content -Path $path
                #domain
                $filteredContent = $content | Where-Object { $_ -like "*Domain*" }
                $filteredContent = $filteredContent.Split(":")
                $domain = $filteredContent[1].Trim()
                #os
                $filteredContent = $content | Where-Object { $_ -like "*OS Name:*" }
                $filteredContent = $filteredContent.Split(":")
                $os = $filteredContent[1].Trim()
                #lastboot
                $filteredContent = $content | Where-Object { $_ -like "*System Boot Time:*" }
                $filteredContent = $filteredContent.Split(":")
                $lastboot = $filteredContent[1].Trim()
                #model
                $filteredContent = $content | Where-Object { $_ -like "*System Model:*" }
                $filteredContent = $filteredContent.Split(":")
                $model = $filteredContent[1].Trim()
                #cpu
                $filteredContent = $content | Where-Object { $_ -like "*Processor(s):*" }
                $filteredContent = $filteredContent.Split(":")
                $cpu = $filteredContent[1].Trim()
                #ram
                $filteredContent = $content | Where-Object { $_ -like "*Total Physical Memory:*" }
                $filteredContent = $filteredContent.Split(":")
                $ram = $filteredContent[1].Trim()
                #hotfixes
                $filteredContent = $content | Where-Object { $_ -like "*Hotfix(s):*" }
                $filteredContent = $filteredContent.Split(":")
                $model = $filteredContent[1].Trim()
                #nics
                $filteredContent = $content | Where-Object { $_ -like "*Network Card(s):*" }
                $filteredContent = $filteredContent.Split(":")
                $nics = $filteredContent[1].Trim() #>
                

                if ($fileName -eq "network_nics__interface_info") {
                    foreach ($row in $importedFile) {
                        $enabled = $row.ConnectionState
                        $dhcp = $row.Dhcp
                        $name = $row.ifAlias
                        if(($enabled -eq "Enabled") -and ($dhcp -eq "Enabled")) {
                            Output-Log -L "warning" -M "`tSYS - The network connection $name has DHCP enabled!"
                            $warningCount++
                        }
                    }
                }
                if ($fileName -eq "eventlog_system") {
                    Output-Log -L "info" -M "SYS - Checking the system log for warnings and errors."
                    $warningtop3 = @{}
                    $warningevents = @{}
                    $errortop3 = @{}
                    $errorevents = @{}
                    foreach ($row in $importedFile) {
                        $message = $row.Message
                        $LevelDisplayName = $row.LevelDisplayName
                        $Id = $row.Id
                        switch ($LevelDisplayName) {
                            "Warning" { 
                                #store the eventid and message in one hashtable
                                if (!($warningevents.ContainsKey($Id))) {
                                    $warningevents.Add($Id, $message)
                                }
                                #let's get a count of the number of messages so we can output the top 3 and count
                                if ($warningtop3.ContainsKey($Id)) {
                                    $warningtop3[$Id]++
                                } else {
                                    $warningtop3.Add($Id, 1)
                                }
                                $warningCount++
                            }
                            "Error" { 
                                #Output-Log -L "error" -M "`tBPA - $title" 
                                if (!($errorevents.ContainsKey($Id))) {
                                    $errorevents.Add($Id, $message)
                                }
                                #let's get a count of the number of messages so we can output the top 3 and count
                                if ($errortop3.ContainsKey($Id)) {
                                    $errortop3[$Id]++
                                } else {
                                    $errortop3.Add($Id, 1)
                                }
                                $errorCount++
                            }
                            Default {}
                        }
                    }
                    # Sort the hashtable by value in descending order
                    $sorted = $warningtop3.GetEnumerator() | Sort-Object -Property Value -Descending
                    # Get the top 3 values
                    $top3 = $sorted | Select-Object -First 3
                    # output the top 3 values
                    Output-Log -L "warn" -M "`tSYS - Here are the top 3 warnings from the system log"
                    foreach ($item in $top3) {
                        $key = $item.Key
                        $count = $item.Value
                        $value = $warningevents.Item($key)
                        $truncatedString = $value.SubString(0,[math]::min(100,$value.length) )
                        #clean up new lines
                        $truncatedString = $truncatedString.Replace("`r`n", "")
                        Output-Log -L "warn" -M "`tSYS - EventId:$key : Count:$count : Message:$truncatedString"
                    }
                    # Sort the hashtable by value in descending order
                    $sorted = $errortop3.GetEnumerator() | Sort-Object -Property Value -Descending
                    # Get the top 3 values
                    $top3 = $sorted | Select-Object -First 3
                    # output the top 3 values
                    Output-Log -L "error" -M "`tSYS - Here are the top 3 errors from the system log"
                    foreach ($item in $top3) {
                        $key = $item.Key
                        $count = $item.Value
                        $value = $errorevents.Item($key)
                        $truncatedString = $value.SubString(0,[math]::min(100,$value.length) )
                        #clean up new lines
                        $truncatedString = $truncatedString.Replace("`r`n", "")
                        Output-Log -L "error" -M "`tSYS - EventId:$key : Count:$count : Message:$truncatedString"
                    }
                } 
                if ($fileName -eq "eventlog_application") {
                    Output-Log -L "info" -M "SYS - Checking the application log for warnings and errors."
                    $warningtop3 = @{}
                    $warningevents = @{}
                    $errortop3 = @{}
                    $errorevents = @{}
                    foreach ($row in $importedFile) {
                        $message = $row.Message
                        $LevelDisplayName = $row.LevelDisplayName
                        $Id = $row.Id
                        switch ($LevelDisplayName) {
                            "Warning" { 
                                #store the eventid and message in one hashtable
                                if (!($warningevents.ContainsKey($Id))) {
                                    $warningevents.Add($Id, $message)
                                }
                                #let's get a count of the number of messages so we can output the top 3 and count
                                if ($warningtop3.ContainsKey($Id)) {
                                    $warningtop3[$Id]++
                                } else {
                                    $warningtop3.Add($Id, 1)
                                }
                                $warningCount++
                            }
                            "Error" { 
                                #Output-Log -L "error" -M "`tBPA - $title" 
                                if (!($errorevents.ContainsKey($Id))) {
                                    $errorevents.Add($Id, $message)
                                }
                                #let's get a count of the number of messages so we can output the top 3 and count
                                if ($errortop3.ContainsKey($Id)) {
                                    $errortop3[$Id]++
                                } else {
                                    $errortop3.Add($Id, 1)
                                }
                                $errorCount++
                            }
                            Default {}
                        }
                    }
                    # Sort the hashtable by value in descending order
                    $sorted = $warningtop3.GetEnumerator() | Sort-Object -Property Value -Descending
                    # Get the top 3 values
                    $top3 = $sorted | Select-Object -First 3
                    # output the top 3 values
                    Output-Log -L "warn" -M "`tSYS - Here are the top 3 warnings from the application log"
                    foreach ($item in $top3) {
                        $key = $item.Key
                        $count = $item.Value
                        $value = $warningevents.Item($key)
                        $truncatedString = $value.SubString(0,[math]::min(100,$value.length) )
                        #clean up new lines
                        $truncatedString = $truncatedString.Replace("`r`n", "")
                        Output-Log -L "warn" -M "`tSYS - EventId:$key : Count:$count : Message:$truncatedString"
                    }
                    # Sort the hashtable by value in descending order
                    $sorted = $errortop3.GetEnumerator() | Sort-Object -Property Value -Descending
                    # Get the top 3 values
                    $top3 = $sorted | Select-Object -First 3
                    # output the top 3 values
                    Output-Log -L "error" -M "`tSYS - Here are the top 3 errors from the application log"
                    foreach ($item in $top3) {
                        $key = $item.Key
                        $count = $item.Value
                        $value = $errorevents.Item($key)
                        $truncatedString = $value.SubString(0,[math]::min(100,$value.length) )
                        #clean up new lines
                        $truncatedString = $truncatedString.Replace("`r`n", "")
                        Output-Log -L "error" -M "`tSYS - EventId:$key : Count:$count : Message:$truncatedString"
                    }
                }
                if ($fileName -eq "eventlog_security") {
                    Output-Log -L "info" -M "SYS - Checking the security log for warnings and errors."
                    $warningtop3 = @{}
                    $warningevents = @{}
                    foreach ($row in $importedFile) {
                        $message = $row.Message
                        $LevelDisplayName = $row.LevelDisplayName
                        $Id = $row.Id
                        if (!($errorevents.ContainsKey($Id))) {
                            $errorevents.Add($Id, $message)
                        }
                        #let's get a count of the number of messages so we can output the top 3 and count
                        if ($errortop3.ContainsKey($Id)) {
                            $errortop3[$Id]++
                        } else {
                            $errortop3.Add($Id, 1)
                        }
                        $errorCount++
                    }
                    # Sort the hashtable by value in descending order
                    $sorted = $errortop3.GetEnumerator() | Sort-Object -Property Value -Descending
                    # Get the top 3 values
                    $top3 = $sorted | Select-Object -First 3
                    # output the top 3 values
                    Output-Log -L "error" -M "`tSYS - Here are the top 3 errors from the security log"
                    foreach ($item in $top3) {
                        $key = $item.Key
                        $count = $item.Value
                        $value = $errorevents.Item($key)
                        $truncatedString = $value.SubString(0,[math]::min(100,$value.length) )
                        #clean up new lines
                        $truncatedString = $truncatedString.Replace("`r`n", "")
                        Output-Log -L "error" -M "`tSYS - EventId:$key : Count:$count : Message:$truncatedString"
                    }
                }              
            }
            #ad
            if ($path -match "ad") {
                #check for at least two dcs
                if (($fileName -match "all_dcs") -and !($count -gt 4)) {
                    Output-Log -L "error" -M "`tAD - There is only one DC!"
                    $errorCount++
                }
                #check replication
            }
            #hyperv
            if ($path -match "hyperv") {
                #check if vms are on C: drive
                #check avail cpu, disk space and memory
            }
            #sql
            if ($path -match "sql") {

            }
            #fs
            if ($path -match "fs") {
                if ($fileName -match "share_permissions") {
                    #Output-Log -L "error" -M "`tDNS - There are more than 2 MX records!"
                    foreach ($row in $importedFile) {
                        $AccountName = $row.AccountName
                        $AccessRight = $row.AccessRight
                        $ShareName = $row.Name
                        $AccessControlType = $row.AccessControlType
                        $namedPerms = $false
                        $denyPerms = $false
                        #check for the everyone accounts per best practices
                        if (!($AccountName -eq "Everyone") -and ($AccessRight -eq "Full")) { #maybe take the read permissions off?
                            $namedPerms = $true
                            $warningCount++
                        }
                        #now check for any deny permissions on the file share perms
                        if ($AccessControlType -eq "Deny") {
                            $denyPerms = $true
                            $errorCount++
                        }                        
                    }
                    if ($namedPerms) {
                        Output-Log -L "warn" -M "`tFS - There are named file share permissions on file share $ShareName!"
                    }
                    if ($denyPerms) {
                        Output-Log -L "error" -M "`tFS - There are DENY file share permissions on file share $ShareName!"
                    }
                }
                if (($fileName -match "fs_blocked_inheritance") -and ($count -gt 1)) {
                    Output-Log -L "warn" -M "`tDNS - There are $count blocked inheritance instances on $filename!"
                    $warningCount++
                }
                #long_file_paths
                if (($fileName -match "long_file_paths") -and ($count -gt 1)) {
                    Output-Log -L "warn" -M "`tDNS - There are $count long file paths on $filename!"
                    $warningCount++
                }
            }
        } 
    }
    Output-Log -L "warn" -M "The client has $warningCount warnings!"
    Output-Log -L "error" -M "The client has $errorCount errors!" 
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}