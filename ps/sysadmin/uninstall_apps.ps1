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

function Get-UninstallString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppName
    )

    $uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

    foreach ($key in $uninstallKeys) {
        $appInfo = Get-ItemProperty -Path $key.PSPath
        if ($appInfo.DisplayName -like "*$AppName*") {
            if($appInfo.QuietUninstallString){
              Output-Log -L "info" -M "Found QuietUninstallString: $($appInfo.QuietUninstallString)"
              return $appInfo.QuietUninstallString
            }
            elseif($appInfo.UninstallString){
              Output-Log -L "info" -M "Found UninstallString: $($appInfo.UninstallString)"
              return $appInfo.UninstallString
            }
            else{
               Output-Log -L "warn" -M "No Uninstall String found for $($appInfo.DisplayName)"
            }
        }
    }
    Output-Log -L "warn" -M "No application found with name containing '$AppName'"
    return $null
}

#the name has to match exactly!
#$app = "@appname@"
#$app = "Duo Desktop"
#$app = "Sentinel Agent"
#$app = "FortiClient VPN"
#$app = "7-zip"
#$app = "Perch Log Shipper"
$app = "Screenconnect*"
$exists = $true
$uninstalled = $false
try {
    #msi
    $MyApp = Get-Package -Provider msi -Name "$app" -ErrorAction Ignore
    if ($MyApp) {
        Output-Log -L "info" -M "Found $app as a MSI, uninstalling the MSI way."
        Uninstall-Package -Name "$($MyApp.Name)"
        exit 0
    } else {
        Output-Log -L "warn" -M "$app isn't installed as a MSI!"
        $exists = $false
    }
    
    #appx
    $MyApp = Get-AppxPackage -Name "$app" #| Remove-AppxPackage
    if ($MyApp) {
        Output-Log -L "info" -M "Found $app with UWP, uninstalling via UWP."
        Remove-AppxPackage -Package "$MyApp"
        exit 0
    } else {
        Output-Log -L "warn" -M "$app isn't installed as a UWP!"
        $exists = $false
    }
    
    #winget
    $MyApp = winget list --name $app
    if ($MyApp) {
        Output-Log -L "info" -M "Found $app with winget, uninstalling via winget."
        winget uninstall --name $app --silent | Out-Null
        exit 0
    } else {
        Output-Log -L "warn" -M "$app isn't installed in winget!"
        $exists = $false
    }

    #wmi
    Output-Log -L "info" -M "Please wait while we query WMI for $app."
    $MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "$app"}
    if ($MyApp) {
        Output-Log -L "info" -M "Found $app with WMI, uninstalling via WMI."
        $MyApp.Uninstall()
        exit 0
    } else {
        Output-Log -L "warn" -M "$app isn't installed in WMI!"
        $exists = $false
    }
    
    #win32 apps that everything else missed
    $MyApp = Get-Package -Provider Programs -Name "$app" -ErrorAction Ignore
    if ($MyApp -and !$uninstalled) {
        Output-Log -L "info" -M "Found $app as a win32 app, uninstalling the registry uninstall string way."
        $uninstallString = Get-UninstallString -AppName $AppName

        if ($uninstallString) {
            Output-Log -L "info" -M "Executing UninstallString: $uninstallString"
            Start-Process -FilePath cmd.exe -ArgumentList "/c $uninstallString" -Wait -ErrorAction Stop
            Output-Log -L "info" -M "Successfully uninstalled '$AppName'"
        }
        else {
            Output-Log -L "warn" -M "Cannot proceed with uninstall for '$AppName' as Uninstall String could not be found."
        }
        exit 0
    } else {
        Output-Log -L "warn" -M "$app isn't installed as a win32 app!"
        $exists = $false
    }

    if ($exists -eq $false) {
        Output-Log -L "error" -M "$app isn't installed at all!"
    }
}
catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}

