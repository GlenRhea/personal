#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator
#,ADSync
#Import-Module ADSync
Clear-Host
#AD
#todo
#email results?
#add inputs for user to enter for domain, dc names, etc
#possibly scan output files for issues and output them in red?
#or have a final html summary report?
$outputPath = "c:\temp\Onboarding"

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

Try {
    if (Test-Path $outputPath) {
        #list dcs
        Output-Log info "All reports will be here: $outputPath"
        $dcs = Get-ADDomainController -filter * | Select-Object name, IPv4Address, IsGlobalCatalog
        $dcs | Out-File -FilePath "$outputPath\all_dcs.txt"
        Output-Log info "Outputting all dcs"

        #get closest dc
        $closestDC = Get-ADDomainController -Discover
        $closestDC | Out-File -FilePath "$outputPath\closest_dc.txt"
        Output-Log info "The closest DC is $closestDC"
        
        #fsmo
        $fsmo = Get-ADDomainController -Filter * | Select-Object Name, OperationMasterRoles
        $fsmo | Out-File -FilePath "$outputPath\fsmo_roles.txt"
        Output-Log info "Outputting all FSMO roles"

        #replication
        $replication = $(Repadmin /replsummary)
        $replication | Out-File -FilePath "$outputPath\replication.txt"
        Output-Log info "Outputting the replication summary"
        
        #gpo
        #lets create a subfolder to put the backed up GPOs in
        New-Item -Path "$outputPath\gpo_backup" -ItemType Directory | Out-Null
        Backup-Gpo -All -Path "$outputPath\gpo_backup" | Out-Null
        Output-Log info "Backing up GPOs to $outputPath\gpo_backup"

        Get-GPOReport -All -ReportType HTML -Path "$outputPath\GPOReport1.html"
        Output-Log info "Outputting GPO information"

        #aad sync
        #Output-Log info "Outputting AAD sync history"
        #Export-ADSyncToolsRunHistory -TargetName MyADSyncHistory
        
        #dns
        #$dnsSettings1 = Get-DnsServerSetting -All -WarningAction:SilentlyContinue
        #$dnsSettings1 | Out-File -FilePath "$outputPath\dns_settings1.txt"
        #Output-Log info "Outputting the DNS settings"
        
        $dnsSettings2 = Get-DnsServer -ComputerName localhost -WarningAction:SilentlyContinue -ErrorAction:SilentlyContinue
        $dnsSettings2 | Out-File -FilePath "$outputPath\dns_settings2.txt"
        Output-Log info "Outputting more DNS settings"

        #$dnsScavenging = Get-DnsServerScavenging
        #$dnsScavenging | Out-File -FilePath "$outputPath\dns_scavenging_settings.txt"
        #Output-Log info "Outputting DNS scavenging settings"

        #check for service accounts

        #collect stats about users and groups
        
        } else {
            Output-Log -L "error" -M "Please enter a valid path!"
        }
} Catch {
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error is: $ErrorMessage"
    Exit 1
}
