. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\ad"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the AD script!"
Output-Log info "AD - All reports will be here: $outputPath"

Try {
    if (Test-Path $outputPath) {
        #list dcs
        $dcs = Get-ADDomainController -filter * | Select-Object name, IPv4Address, IsGlobalCatalog
        #Get-ADDomainController -Filter *
        $dcs | Export-Csv -Path "$outputPath\all_dcs.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting all dcs"

        #check functional level
        #Get-ADDomain | Select-Object DomainMode

        #get closest dc
        $closestDC = Get-ADDomainController -Discover
        $closestDC | Export-Csv -Path "$outputPath\closest_dc.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - The closest DC is $closestDC"

        #get pw policies
        $policy = Get-ADDefaultDomainPasswordPolicy
        $policy | Export-Csv -Path "$outputPath\ad_policy.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting default domain password policies"
        
        #get audit policies
        #auditpol /backup /file:$outputPath\ad_audit_policy.csv
        #keep the one from the module, its much easier to parse
        $policy = Get-SecurityAuditPolicy
        $policy | Export-Csv -Path "$outputPath\ad_audit_policy.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting default domain audit policies"

        #fsmo
        $fsmo = Get-ADDomainController -Filter * | Select-Object Name, OperationMasterRoles
        #Get-ADDomain instead?
        $fsmo | Export-Csv -Path "$outputPath\fsmo_roles.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting all FSMO roles"

        #replication
        $replication = $(Repadmin /replsummary)
        #this will also do it
        #Get-ADReplicationPartnerMetadata -Target <DC_Name>
        $replication | Export-Csv -Path "$outputPath\replication.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting the replication summary"
        
        #gpo
        #lets create a subfolder to put the backed up GPOs in
        $outputPath = "$outputPath\gpo_backup"
        if (!(Test-Path $outputPath)) {
            New-Item -Path "$outputPath\gpo_backup" -ItemType Directory | Out-Null
            Backup-Gpo -All -Path "$outputPath\gpo_backup" | Out-Null
            Output-Log info "AD - Backing up GPOs to $outputPath\gpo_backup"

            Get-GPOReport -All -ReportType HTML -Path "$outputPath\GPOReport1.html"
            Output-Log info "AD - Outputting GPO information"
        } else {
            Output-Log info "AD - GPO folder already exists!"
        }
        
        $outputPath = "$outputPath\modules\ad"
        #aad sync
        #Output-Log info "Outputting AAD sync history"
        #Export-ADSyncToolsRunHistory -TargetName MyADSyncHistory
        
        $dnsSettings2 = Get-DnsServer -ComputerName localhost -WarningAction:SilentlyContinue -ErrorAction:SilentlyContinue
        $dnsSettings2 | Out-File -FilePath "$outputPath\dns_settings2.csv" -Encoding utf8
        #csv doesn't work for this one
        #$dnsSettings2 | Export-Csv -Path "$outputPath\dns_settings2.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting more DNS settings"

        #$dn = Get-ADRootDSE | Select-Object defaultNamingContext
        #$dn = $dn.defaultNamingContext
        #$tl = $(get-adobject “cn=Directory Service,cn=Windows NT,cn=Services,cn=Configuration,DC=ad,$dn” -properties “tombstonelifetime”).tombstonelifetime
        #$dnsSettings2 | Out-File -FilePath "$outputPath\dns_settings2.csv" -Encoding utf8
        #csv doesn't work for this one
        #$dnsSettings2 | Export-Csv -Path "$outputPath\dns_settings2.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "AD - Outputting more DNS settings"

        #check for service accounts
        $serviceaccounts = get-aduser -filter * -properties Name, PasswordNeverExpires | Where-Object { $_.passwordNeverExpires -eq "true" } | Where-Object {$_.enabled -eq "true"} 
        $serviceaccounts | Export-Csv -Path "$outputPath\service_accounts.csv" -NoTypeInformation  -Encoding UTF8 -Force
        Output-Log info "AD - Outputting accounts with no password expiration (service accounts)"

        #chech for accounts with spaces in the samaccountname, ugh

        #get all groups and group memberships
        #create the csv and add the header
        $header = "GroupName,Member"
        $header | Out-File -FilePath "$outputPath\group_membership.csv"
        $groups = Get-ADGroup -Filter *
        foreach ($group in $groups) {
            $name = $group.Name
            $members = Get-ADGroupMember -Identity "$name" -Recursive
            foreach ($member in $members) {
                $memberName = $member.Name
                $output = "$name,$memberName"
                $output | Out-File -Append -FilePath "$outputPath\group_membership.csv"
            }
        }
        Output-Log info "AD - Outputting groups and permissions"

        #collect stats about users and groups
        $allaccounts = get-aduser -filter * -properties Name, PasswordNeverExpires | Where-Object {$_.enabled -eq "true"}
        $userCount = $allaccounts.Count
        Output-Log info "AD - There are $userCount users." 
        $groupCount = $groups.Count
        Output-Log info "AD - There are $groupCount groups." 

        
        } else {
            Output-Log -L "error" -M "Please enter a valid path!"
        }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
