function Output-Log {
    Param( 
           [Parameter(Mandatory)]
           [ValidateSet('info','warn', 'error')]
           [alias("L")] 
           [string]$LogLevel, 
    
           [alias("M")] 
           [string]$msg
       ) 
    $outputPath = "c:\temp\intune_install_output.txt"
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
    #Output-Log -L "info" -M "The error on line # $errorLine is: $ErrorMessage"
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"

}
