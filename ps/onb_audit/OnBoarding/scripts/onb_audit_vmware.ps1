#Requires -RunAsAdministrator

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\vmware"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the HyperV script!"
Output-Log info "VMW - All reports will be here: $outputPath"

Try {
    if (Test-Path $outputPath) {
        #install the vmware powershell modules
        & .\onb_audit_modules.ps1 "VMware.PowerCLI"

        #connect to vcenter if they have it
        Connect-VIServer -Server vc1.example.com -Protocol http -User 'MyAdministratorUser' -Password 'MyPassword'

        #we're going to assume it's installed from the BPA script when it executes it
        $output = Get-Datacenter DC | Get-VMHost | Format-Custom
        $output | Export-Csv -Path "$outputPath\vmhost.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "VMW - Outputting host info"

        #get info on all VMs
        $vms = Get-VM | Select-Object Name, PowerState, NumCpu, MemoryGB, ProvisionedSpaceGB, UsedSpaceGB, Version
        $vms | Export-Csv -Path "$outputPath\all_vms.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "VMW - Outputting VM info"

        #get info on all VHDs
        $output = ""
        foreach ($vm in $vms) {
            $disks = Get-HardDisk -VM $vm.Name
            $disks | Export-Csv -Path "$outputPath\all_vhds.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "VMW - Outputting VHD info"

        #get info on all VH NICs
        $output = ""
        foreach ($vm in $vms) {
            $nics = Get-VMHostNetworkAdapter -VMN $vm.Name | select VMhost, Name, IP, SubnetMask, Mac
            $nics | Export-Csv -Path "$outputPath\all_vm_nics.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "VMW - Outputting VM NIC info"

        #get info on all VH Security Info
        $output = ""
        foreach ($vm in $vms) {
            $secInfo = Get-SecurityInfo -VMName $vm.Name
            $secInfo | Export-Csv -Path "$outputPath\all_vm_secinfo.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "VMW - Outputting VM security info"

        #get info on all VH snapshots
        $output = ""
        foreach ($vm in $vms) {
            $snapshots = Get-Snapshot -VMName $vm.Name
            $snapshots | Export-Csv -Path "$outputPath\all_vm_snapshots.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "VMW - Outputting VM security info"

        #get info on all vmswitches
        $output = Get-VirtualSwitch
        $output | Export-Csv -Path "$outputPath\vm_switches.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "VMW - Outputting vSwitches info"
        
        #get info on all VM SANs
        $output = Get-VsanDiskGroup
        $output | Export-Csv -Path "$outputPath\vm_sans.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "VMW - Outputting VM info"

        <# } else {
            Output-Log warn "VMW - VMware isn't installed!"
        } #>
    } else {
        Output-Log -L "error" -M "VMW - Please enter a valid path!"
    }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
