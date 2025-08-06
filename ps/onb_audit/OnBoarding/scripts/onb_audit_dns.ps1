#Requires -Modules DomainHealthChecker

. .\onb_audit_functions.ps1

#AD
#todo

#references
#https://github.com/T13nn3s/Invoke-SpfDkimDmarc

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\dns"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the DNS script!"
Output-Log info "DNS - All reports will be here: $outputPath"



Try {
    if (Test-Path $outputPath) {
        #add ability to have multiple domains here, separated by a comma
        $domain = $domain.split(',')
        foreach ($dom in $domain) {
            #get spf, dkim and dmarc
            Output-Log info "DNS - Getting spf, dkim and dmarc for $dom."
            $spfdkimdmarc = Invoke-SpfDkimDmarc -Name $dom
            $spfdkimdmarc | Export-Csv -Path  "$outputPath\spfdkimdmarc.csv" -NoTypeInformation -Encoding UTF8 -Force -Append
            
            #check MX records
            Output-Log info "DNS - Getting MX records for $dom."
            $mxrecords = Resolve-DnsName -Name "$dom" -Type MX
            $mxrecords | Export-Csv -Path  "$outputPath\mxrecords.csv" -NoTypeInformation -Encoding UTF8 -Force -append
            
            #check for a hybrid dns env
        }
    } else {
            Output-Log -L "error" -M "Please enter a valid path!"
    }
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
