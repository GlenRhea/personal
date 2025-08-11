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
$userswithspaces = $false
try {
    Output-Log -L "info" -M "Pulling user list"
    $users = Get-ADUser -Filter *
    Output-Log -L "info" -M "There are $($users.count) total users"
    Output-Log -L "info" -M "Checking for spaces in the usernames"
    foreach ($user in $users) {
        $user = $user.samaccountname
        #if ($user -match "\s") { 
        if (($user -match "\s") -and ($user -eq "Remote Support" -or $user -eq "ABC NOC")) { 
            Output-Log -L "warn" -M "`"$user`" has a space"
            #now that we've identified them, let's replace the space with an underscore
            $usernospaces = $user -replace " ", "_"
            $usernospaces
            #Set-ADUser -Identity "$user" -SamAccountName $usernospaces
            Output-Log -L "info" -M "Replaced `"$user`" with $usernospaces"
            $userswithspaces = $true
        }
    }
    if (!$userswithspaces) {
        Output-Log -L "info" -M "There are no users with spaces in the names"
    }
}
catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
