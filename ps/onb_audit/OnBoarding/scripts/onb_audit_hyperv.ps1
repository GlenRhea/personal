#Requires -RunAsAdministrator

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\hyperv"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the HyperV script!"
Output-Log info "HYP - All reports will be here: $outputPath"

Try {
    if (Test-Path $outputPath) {
        #check to see if hyperv is even installed
        #$hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
        # Check if Hyper-V is enabled
        #if($hyperv.State -eq "Enabled") {
            #get basic hyperv info
        #we're going to assume it's installed from the BPA script when it executes it
        $output = Get-VMHost
        $output | Export-Csv -Path "$outputPath\vmhost.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "HYP - Outputting host info"

        #get info on all VMs
        $vms = Get-VM | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime, Status, Version, Path
        $vms | Export-Csv -Path "$outputPath\all_vms.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "HYP - Outputting VM info"

        #get info on all VHDs
        $output = ""
        foreach ($vm in $vms) {
            $disks = Get-VMHardDiskDrive -VMName $vm.Name
            $disks | Export-Csv -Path "$outputPath\all_vhds.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "HYP - Outputting VHD info"

        #get info on all VH NICs
        $output = ""
        foreach ($vm in $vms) {
            $nics = Get-VMNetworkAdapter -VMName $vm.Name
            $nics | Export-Csv -Path "$outputPath\all_vm_nics.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "HYP - Outputting VM NIC info"

        #get info on all VH Security Info
        $output = ""
        foreach ($vm in $vms) {
            $secInfo = Get-VMSecurity -VMName $vm.Name
            $secInfo | Export-Csv -Path "$outputPath\all_vm_secinfo.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "HYP - Outputting VM security info"

        #get info on all VH snapshots
        $output = ""
        foreach ($vm in $vms) {
            $snapshots = Get-VMSnapshot -VMName $vm.Name
            $snapshots | Export-Csv -Path "$outputPath\all_vm_snapshots.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
        }
        Output-Log info "HYP - Outputting VM security info"

        #get info on all vmswitches
        $output = Get-VMSwitch
        $output | Export-Csv -Path "$outputPath\vm_switches.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "HYP - Outputting vSwitches info"
        
        #get info on all VM SANs
        $output = Get-VMSan
        $output | Export-Csv -Path "$outputPath\vm_sans.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "HYP - Outputting VM info"

        <# } else {
            Output-Log warn "HYP - HyperV isn't installed!"
        } #>
    } else {
        Output-Log -L "error" -M "HYP - Please enter a valid path!"
    }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
