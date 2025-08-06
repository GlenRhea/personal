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
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}