#Requires -RunAsAdministrator

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\sysadmin"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the Sysadmin script!"
Output-Log info "SYS - All reports will be here: $outputPath"

Try {
    if (Test-Path $outputPath) {
        #install the auditing module
        & .\onb_audit_modules.ps1 "SecurityFever"
        #get basic computer info
        #this command doesn't work on older servers
        #$computerinfo = Get-ComputerInfo
        $computerinfo = systeminfo.exe
        $computerinfo | Out-File -FilePath "$outputPath\systeminfo.txt"
        #$computerinfo | Export-Csv -Path "$outputPath\systeminfo.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all system info"

        #get avg cpu utilization oover 1 minute
        $cpuAvgUtil = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 60 | Select-Object -ExpandProperty CounterSamples | Measure-Object -Property CookedValue -Average | Select-Object -ExpandProperty Average
        #$computerinfo | Export-Csv -Path "$outputPath\computerinfo.csv" -NoTypeInformation -Encoding UTF8 -Force
        $cpuAvgUtil | Out-File -FilePath "$outputPath\avg_cpu.txt"
        Output-Log info "SYS - Outputting average cpu utilization over 1 minute"

        #get basic memory info
        $mem = Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
        $totalmemory = $mem.TotalVisibleMemorySize
        $freememory = $mem.FreePhysicalMemory
        $percentFree =  [math]::Round(($freememory / $totalmemory) * 100)
        $memoryInfo = @{
            totalmemory = $totalmemory;
            freememory = $freememory;
            percentFree = $percentFree
        }
        #get the enumerator so it can output to csv
        $memoryInfo = $memoryInfo.GetEnumerator()
        $memoryInfo | Export-Csv -Path "$outputPath\memoryinfo.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all memory info"

        #get basic disk info
        $volumes = Get-Volume
        $volumes | Export-Csv -Path "$outputPath\disk_volumes.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all volume info"

        #get unallocated disk space
        $volumes = Get-Disk | Where-Object PartitionStyle -eq 'RAW'
        $volumes | Export-Csv -Path "$outputPath\disk_unallocated_space.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all unallocated disk space"

        #get windows firewall status
        $volumes = Get-NetFirewallProfile -PolicyStore activestore
        $volumes | Export-Csv -Path "$outputPath\network_firewall_status.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting windows firewall info"

        #now gather network info
        #get list of nics and current ip configs
        #get all nics
        $nics = Get-NetAdapter -Name *
        $nics | Export-Csv -Path "$outputPath\network_nics.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting basic NIC info"
        
        #get advanced nic info
        $nics = Get-NetAdapterAdvancedProperty -Name "*" -AllProperties
        $nics | Export-Csv -Path "$outputPath\network_nics_advanced.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting advanced NIC info"
        
        #get all hardware info
        $nics = Get-NetAdapterHardwareInfo -Name "*" | Format-List -Property "*"
        $nics | Export-Csv -Path "$outputPath\network_nics_hardware.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all NIC hardware info"

        #get network info from nics
        $nics = Get-NetIPConfiguration
        $nics | Export-Csv -Path "$outputPath\network_nics_networkinfo.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all NIC network info"

        #get more network info from nics
        $nics = Get-NetIPAddress
        $nics | Export-Csv -Path "$outputPath\network_nics__more_networkinfo.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting more NIC network info"

        #check for dhcp or static ip
        $nics = Get-NetIPInterface
        $nics | Export-Csv -Path "$outputPath\network_nics__interface_info.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting network interface info"
        
        #get routing table
        $nics = Get-NetRoute
        $nics | Export-Csv -Path "$outputPath\network_routing_info.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting all routing info"

        #get arp info
        $nics = Get-NetNeighbor
        $nics | Export-Csv -Path "$outputPath\network_arp_info.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting ARP table"

        #get windows service audit
        $output = Get-SystemAuditWindowsService
        $output | Export-Csv -Path "$outputPath\audit_winservices.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting windows service audit"

        #get windows msi audit
        $output = Get-SystemAuditMsiInstaller
        $output | Export-Csv -Path "$outputPath\audit_msi-installs.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting windows msi audit"

        #event viewer logs, warnings and errors
        #got this error on server 2022:
        #Get-WinEvent : No events were found that match the specified selection criteria.
        #get event logs - system
        #$eventLogs = Get-EventLog -LogName System -EntryType Error, Warning 
        $eventlogs = Get-WinEvent -FilterHashTable @{LogName='System';Level=2,3} -MaxEvents 5000
        $eventLogs | Export-Csv -Path "$outputPath\eventlog_system.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting top 5000 errors and warnings from system logs"

        #get event logs - apps
        #$eventLogs = Get-EventLog -LogName Application -EntryType Error, Warning 
        $eventlogs = Get-WinEvent -FilterHashTable @{LogName='Application';Level=2,3} -MaxEvents 5000
        $eventLogs | Export-Csv -Path "$outputPath\eventlog_application.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting top 5000 errors and warnings from application logs"

        #get event logs - security
        #$eventLogs = Get-EventLog Security -EntryType FailureAudit
        $eventLogs = Get-WinEvent -FilterHashtable @{LogName='Security';Keywords='4503599627370496'} -MaxEvents 5000
        $eventLogs | Export-Csv -Path "$outputPath\eventlog_security.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SYS - Outputting top 5000 errors and warnings from security logs"

    } else {
        Output-Log -L "error" -M "SYS - Please enter a valid path!"
    }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
