#Requires -RunAsAdministrator
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

try {
    $installDir = "c:\temp"
    if (!(Test-Path $installDir)) {
        New-Item -ItemType directory -Force -Path $installDir
        Output-Log -L "info" -M "Creating the admin folder."
    } else {
        Output-Log -L "info" -M "The admin folder already exists, not creating."
    }

    #clear out any previous files
    if (Test-Path "$installDir\onboarding.zip") {
        Remove-Item -Force -Path "$installDir\onboarding.zip"
        Output-Log -L "info" -M "Creating the admin folder."
    }
    if (Test-Path "$installDir\onboarding\") {
        Remove-Item -Recurse -Force -Path "$installDir\onboarding\"
        Output-Log -L "info" -M "Creating the admin folder."
    }

    #now download the zipfile
    #for older OSs
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest 'https://yourownhosting.com/OnBoarding/OnBoarding.zip' -OutFile "$installDir\OnBoarding.zip"
    Output-Log -L "info" -M "Downloaded the onb_audit zip file from Azure."

    #now unzip the file
    #this doesn't work on server 2012, maybe download 7zip and use that instead?
    $osVersion = (Get-CimInstance Win32_OperatingSystem).version
    $osVersion = $osVersion.split(".")
    $osVersion = [int32]$osVersion[0]
    if ($osVersion -gt 6) {
        Expand-Archive -Path "$installDir\OnBoarding.zip" -DestinationPath $installDir
        Output-Log -L "info" -M "Unzipped with Expand-Archive."
    } else {
        #os is too old for expand-archive, install 7zip instead
        #check to see if it's already installed first
        if (!(Test-Path "c:\Program Files\7-Zip\7z.exe")) {
            Invoke-WebRequest 'https://yourownhosting.com/7z2408-x64.msi' -OutFile "$installDir\7z2408-x64.msi"
            $pkg = "$installDir\7z2408-x64.msi"
            Start-Process msiexec "/i $pkg /qn"
            Start-Sleep -Seconds 3
            #now unzip the file
            Set-Location $installDir
            ."c:\Program Files\7-Zip\7z.exe" x c:\temp\OnBoarding.zip -y -aoa > $null
            Output-Log -L "info" -M "Unzipped with 7zip."
        } else {
            Set-Location $installDir
            ."c:\Program Files\7-Zip\7z.exe" x c:\temp\OnBoarding.zip -y -aoa > $null
            Output-Log -L "info" -M "Unzipped with 7zip."
        }
    }
    
    Start-Sleep -Seconds 3

    Set-Location "$installDir\Onboarding\scripts"
    Output-Log -L "info" -M "Changed path to $installDir\Onboarding\scripts."

    #now add the dynamic variables from RMM
    <# $Verbose = "@Verbose@"
    $Verbose = [system.convert]::ToBoolean($Verbose)
    $SendTo = "@SendTo@"
    $DomainToCheck = "@DomainToCheck@" #>
    $Verbose = Read-Host "Verbose output? (y/n): "
    $Verbose = $Verbose.ToLower()
    if ($Verbose -eq "y") {
        $Verbose = $true
    } else {
        $Verbose = $false
    }
    $SendTo = Read-Host "Enter email to receive output?: "
    if ([string]::IsNullOrEmpty($SendTo)) {
        Write-Host "Email address is required, try again."
        Exit 1
    }
    $DomainToCheck = Read-Host "Domain for DNS checks?: "
    if ([string]::IsNullOrEmpty($SendTo)) {
        Write-Host "Domain is required, try again."
        Exit 1
    }
    #.\onb_audit_functions.ps1 "$SendTo" "$DomainToCheck" $Verbose
    Add-Content -Path .\onb_audit_variables.ps1 -Value "`r`n`$domain = `"$DomainToCheck`""
    Add-Content -Path .\onb_audit_variables.ps1 -Value "`r`n`$SendTo = `"$SendTo`""
    if ($Verbose) {
        Add-Content -Path .\onb_audit_variables.ps1 -Value "`r`n`$Verbose = `$true"
    }
    Output-Log -L "info" -M "Added the variables to the variables script."
    
    #start the master script separately, it created a loop otherwise
    .\onb_audit_master
    Output-Log -L "info" -M "Started the onb_audit master script and will send the output file to $SendTo."
} Catch {
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "START = The error is: $ErrorMessage"
}
