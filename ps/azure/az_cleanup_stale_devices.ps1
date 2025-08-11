function Output-Log {
    Param( 
           [Parameter(Mandatory)]
           [ValidateSet('info','warn', 'error')]
           [alias("L")] 
           [string]$LogLevel, 
    
           [alias("M")] 
           [string]$msg
       ) 
    $outputPath = "c:\temp\stale_devices.txt"
    if (!(Test-Path $outputPath)) {
        $null = New-Item -ItemType File -Force -Path $outputPath
    }

    $date = Get-Date
    #$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
    $output = $date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
    switch ($LogLevel) {
        warn { Write-Host -ForegroundColor Yellow $output}
        error { Write-Host -ForegroundColor Red $output}
        Default { Write-Host -ForegroundColor Green $output }
    }
    $output | Out-File -FilePath $outputPath -Append
}

try {
    #add actual code here and use this for outputting to the console:
    Output-Log -L "info" -M "Pulling list of devices."
    Connect-MgGraph -NoWelcome
    #let's go back 6 months
    $dt = (Get-Date).AddDays(-180)
    $devices = Get-MgDevice -All | Where-Object {$_.ApproximateLastSignInDateTime -le $dt} | 
        select-object -Property Id, AccountEnabled, DeviceId, OperatingSystem, OperatingSystemVersion, DisplayName, TrustType, ApproximateLastSignInDateTime #| 
        #export-csv devicelist-olderthan-90days-summary.csv -Encoding utf8 -NoTypeInformation
    Output-Log -L "info" -M "There are $($devices.count) devices before checking for null last active dates."
    #check to see if the last active date is actually populated
    $cleanedDevices = @()

    foreach ($device in $devices) {
        $ApproximateLastSignInDateTime = $device.ApproximateLastSignInDateTime
        if($null -eq $ApproximateLastSignInDateTime) {
            Output-Log warn "$($device.DisplayName) doesn't have a last active time set, removing from the list!"
            #$devices.Methods.Remove($device)
        } else {
            #this is the best way to add a ps custom object to an array!
            $cleanedDevices += @($device)
        }    
    }
    
    Output-Log -L "info" -M "There are $($cleanedDevices.count) devices after checking for null last active dates."

    #now loop through the devices and either disable or delete them
    foreach ($cleanedDevice in $cleanedDevices) {
        #we will use the device ID to disable/remove
        #$deviceID = $cleanedDevice.DeviceId
        $deviceID = $cleanedDevice.Id
        $displayName = $cleanedDevice.DisplayName
        $ApproximateLastSignInDateTime = $cleanedDevice.ApproximateLastSignInDateTime
        $AccountEnabled = $cleanedDevice.AccountEnabled
        
        #to disable
        $params = @{
            accountEnabled = $false
        }

         #delete anything over 6 months old that was disabled from the previous runs
        if (($ApproximateLastSignInDateTime -gt $dt) -and (!$AccountEnabled)) {
            Remove-MgDevice -DeviceId $deviceID
            Output-Log -L "info" -M "Deleted $displayName."
        }

        #disable all of them
        Update-MgDevice -DeviceId $deviceID -BodyParameter $params 
        Output-Log -L "info" -M "Disabled $displayName."
    }

    #export the results
    $cleanedDevices | Export-Csv -Path "c:\temp\stale_entra_devices.csv" -Encoding utf8 -NoTypeInformation
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}