function Output-Log {
    Param( 
        [Parameter(Mandatory)]
        [ValidateSet('info', 'warn', 'error')]
        [alias("L")] 
        [string]$LogLevel, 
    
        [alias("M")] 
        [string]$msg
    ) 
    $date = Get-Date
    #$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
    $output = $date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
    switch ($LogLevel) {
        warn { Write-Host -ForegroundColor Yellow $output }
        error { Write-Host -ForegroundColor Red $output }
        Default { Write-Host -ForegroundColor Green $output }
    }
}

try {
    #add actual code here and use this for outputting to the console:
    #Output-Log -L "info" -M "The error on line # $errorLine is: $ErrorMessage"
    
    #reference
    #https://call4cloud.nl/2020/05/intune-auto-mdm-enrollment-for-devices-already-azure-ad-joined/
    # Set MDM Enrollment URL's
    #set tenant ID GUID
    $tenantID = ""
    #$tenantID = "@tenant_id@"
    $key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\'

    $test = test-path -path "HKLM:\$key\$tenantID"

    if(-not($test)){
        New-Item -Path "HKLM:\$key" -Force | Out-Null
        sleep 3
        #now create the tenant id guid folder
        New-Item -Path "HKLM:\$key\$tenantID" -Force  | Out-Null
    }

    <# try{
        $keyinfo = Get-Item "HKLM:\$key\$tenantID"
    } catch {
        #Write-Host "Tenant ID is not found!"
        Output-Log -L "error" -M "Tenant ID is not found!"
        exit 1001
    } #>

    #$url = $keyinfo.name
    #$url = $url.Split("\")[-1]
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$tenantID"
    $keyinfo = Get-ItemProperty $path
    #if(!(Test-Path $path)){
    if (!($null -eq $keyinfo)) {
        $enrollment = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$tenantID\MdmEnrollmentUrl"
        if(!(Test-Path $enrollment)){
            #Get-ItemProperty $path -Name MdmEnrollmentUrl
        
            #Write_Host "MDM Enrollment registry keys not found. Registering now..."
            Output-Log -L "info" -M "MDM Enrollment registry keys not found. Registering now..."
            New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ea SilentlyContinue | Out-Null
            New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ea SilentlyContinue | Out-Null
            New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ea SilentlyContinue | Out-Null
            
            sleep 3
            # Trigger AutoEnroll with the deviceenroller
        
                C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM
                #Write-Host "Device is performing the MDM enrollment!"
                Output-Log -L "info" -M "Device is performing the MDM enrollment!"
            #exit 0
        
                #Write-Host "Something went wrong (C:\Windows\system32\deviceenroller.exe)"
                #Output-Log -L "error" -M "Something went wrong (C:\Windows\system32\deviceenroller.exe)"
            #exit 1001          
        

        }
    } else {
        C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM
        #Write-Host "Device is performing the MDM enrollment!"
        Output-Log -L "info" -M "Device is performing the MDM enrollment!"
    }

} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}

