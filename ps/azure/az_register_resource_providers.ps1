Import-Module Az

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
#reference:
#https://nmehelp.getnerdio.com/hc/en-us/articles/26734007762189-What-Azure-Resource-Providers-are-Required
$rps = @("Microsoft.KeyVault","Microsoft.Compute","Microsoft.Automation","Microsoft.Storage","Microsoft.Insights","Microsoft.OperationalInsights","Microsoft.DesktopVirtualization","Microsoft.Network","Microsoft.AAD","Microsoft.RecoveryServices")
try {
    foreach ($rp in $rps) {
        Register-AzResourceProvider -ProviderNamespace $rp
        Output-Log info "Registered $rp provider"
    }    
}
catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}

