#Requires -RunAsAdministrator

Clear-Host

#call the functions and variables script
. .\onb_audit_functions.ps1

if (!(Test-Path $outputPath)) {
    New-Item -ItemType directory -Force -Path $outputPath
}

Output-Log warn "Starting the onb_audit scripts!"
Output-Log info "Master - All reports will be here: $outputPath"
try {
    #start bpa script first, that should handle the majority of the module scripts
    Output-Log info "Master - Starting the BPA script"
    & .\onb_audit_bpa.ps1

    #since sql server isn't installed as a role we will check for it here
    Output-Log info "Master - Starting the SQL script"
    if (Test-Path "HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL") {
        & .\onb_audit_modules.ps1 "SqlServer"
        Output-Log info "SQL - SQL Server is installed, starting..."
        & .\onb_audit_sql.ps1
    } else {
        Output-Log info "SQL - SQL Server is NOT installed, skipping..."
    }

    #now gather all the sysadmin data
    Output-Log info "Master - Starting the Sysadmin script"
    & .\onb_audit_sysadmin.ps1

    #zip up the results
    $hostname = $env:COMPUTERNAME
    $filename = "$outputPath\$hostname`_modules.zip"
    ZipFile -P "$outputPath\modules\" -D $filename
    Output-Log info "Master - Zipped up output here: $filename"

    #send email with file
    Start-Sleep 5
    SendEmail -S "Onb_audit results for $hostname" -B "The onb_audit script output for $hostname is attached" -F $filename
    
    #after zip has been created need to cleanup scripts 
    Remove-Item -Path "$outputPath\scripts\*.ps1" 
    Output-Log info "Master - Cleaned up scripts"
    Remove-Item -Path "c:\temp\OnBoarding.zip" 
    Output-Log info "Master - Cleaned up main zip file"

    Output-Log info "Master - All tasks are complete"
    #testing devops build again

} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
