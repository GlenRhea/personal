# Import the necessary modules
#Import-Module ActiveDirectory
#Import-Module Microsoft.Graph
Import-Module AzureAD

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

#Install-Module ActiveDirectory
#Install-Module Microsoft.Graph
#need this for server 2016
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Install-Module AzureAD -Confirm:$False


try {
    #upn only works if AD is using a routable domain for the UPN, not a .local or something
    #maybe check using the samaccountname instead?
    #looks like we'll have to strip the @domain.com part of the UPN to check them

    # Connect to Microsoft Graph (Entra ID)
    #Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
    Connect-AzureAD | Out-Null

    # Get all users from Active Directory
    $adUsersSAN = Get-ADUser -Filter 'Enabled -eq $true -and UserPrincipalName -like "*@*"' -Properties SamAccountName | Select-Object SamAccountName
    $adUsers = @()
    foreach ($user in $adUsersSAN) {
        $adUsers += $user.SamAccountName
    }

    # Get all users from Entra ID
    #$entraUsersUPN = Get-MgUser -All | Select-Object UserPrincipalName
    $entraUsersUPN = Get-AzureADUser -All $true | Select-Object UserPrincipalName
    $entraUsers = @()
    foreach ($user in $entraUsersUPN) {
        $username = ($user.UserPrincipalName -split "@")[0]
        $entraUsers += $username
    }
    
    # Compare the two lists and find duplicates
    #$duplicates = Compare-Object $adUsers $entraUsers -Property UserPrincipalName -IncludeEqual -ExcludeDifferent |
    #$comparison = Compare-Object $adUsers $entraUsers -Property UserPrincipalName -IncludeEqual #|
    $comparison = Compare-Object $adUsers $entraUsers -IncludeEqual #|
        #Where-Object {$_.SideIndicator -eq "=="} |
        #Select-Object UserPrincipalName

    #Compare-Object $adUsers $entraUsers -Property UserPrincipalName -IncludeEqual

    #would like to show same and different both
    $duplicates = $comparison | Where-Object {$_.SideIndicator -eq "=="} #| Select-Object UserPrincipalName
    $adonly = $comparison | Where-Object {$_.SideIndicator -eq "<="} #| Select-Object UserPrincipalName
    $entraonly  = $comparison | Where-Object {$_.SideIndicator -eq "=>"} #| Select-Object UserPrincipalName

    # Output the duplicate UserPrincipalNames
    if ($duplicates) {
        Output-Log warn "Duplicate UserPrincipalNames found: $($duplicates.count)"
        #Output-Log warn "Outputting list:"
        #Write-Warning "Duplicate UserPrincipalNames found $($duplicates.count):"
        $duplicates | ForEach-Object {
            #Write-Host $_.UserPrincipalName
            #Output-Log warn "`t$($_.UserPrincipalName)"
            Output-Log info "`t$($_.InputObject)"
        }
    } else {
        Output-Log info "No duplicate UserPrincipalNames found."
    }

    # Output the duplicate UserPrincipalNames
    if ($adonly) {
        Output-Log warn "Users only in AD: $($adonly.count)"
        #Output-Log info "Outputting list:"
        #Write-Warning "Duplicate UserPrincipalNames found $($duplicates.count):"
        $adonly | ForEach-Object {
            #Output-Log info "`t$($_.UserPrincipalName)"
            Output-Log info "`t$($_.InputObject)"
        }
    }

    if ($entraonly) {
        Output-Log warn "Users only in Entra: $($entraonly.count)"
        #Output-Log info "Outputting list:"
        #Write-Warning "Duplicate UserPrincipalNames found $($duplicates.count):"
        $entraonly | ForEach-Object {
            Output-Log info "`t$($_.InputObject)"
        }
    }

    #output to csv
    $comparison | Export-Csv -Path "c:\temp\ad_check_dupes_aad.csv" -NoTypeInformation -Encoding UTF8 -Force

    # Disconnect from Microsoft Graph
    #Disconnect-MgGraph | Out-Null
    Disconnect-AzureAD | Out-Null
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}

