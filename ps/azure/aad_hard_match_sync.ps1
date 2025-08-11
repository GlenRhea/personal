# =================================================================================================
# Script to set the Azure AD onPremisesImmutableId from the on-premises AD objectGUID
# using the Microsoft Graph PowerShell SDK.
#
# Prerequisites:
# 1. Microsoft Graph PowerShell SDK (Install-Module Microsoft.Graph)
# 2. Active Directory PowerShell Module (Part of RSAT)
# 3. Run this script from a domain-joined computer.
# 4. Credentials for an account with User Administrator or Global Administrator role in Azure AD.
# 5. MAKE SURE THERE AREN'T ANY SOFT DELETED USERS THAT WERE DUPLICATES FIRST!!!!!
# =================================================================================================

# --- Define required permissions for Microsoft Graph ---
$requiredScopes = @("User.Read.All", "User.ReadWrite.All")

# --- Connect to Microsoft Graph ---
try {
    Write-Host "Connecting to Microsoft Graph. You may be prompted to log in and provide admin consent."
    Connect-MgGraph -Scopes $requiredScopes -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Please ensure the SDK is installed and you have the necessary permissions." -ForegroundColor Red
    return
}

# --- Get all users from On-Premises Active Directory ---
try {
    Write-Host "Getting all users from on-premises Active Directory..."
    $adUsers = Get-ADUser -Filter * -Properties objectGUID, UserPrincipalName
    if (-not $adUsers) {
        Write-Host "No users found in Active Directory." -ForegroundColor Yellow
        return
    }
    Write-Host "Found $($adUsers.Count) users in Active Directory." -ForegroundColor Green
}
catch {
    Write-Host "Failed to get users from Active Directory. Ensure the AD PowerShell module is available and you have permissions." -ForegroundColor Red
    return
}

# --- Loop through each AD user and update the corresponding Azure AD user ---
Write-Host "Starting the process to update onPremisesImmutableId in Azure AD..."

foreach ($adUser in $adUsers) {
    # --- Skip users without a UPN ---
    if (-not $adUser.UserPrincipalName) {
        Write-Host "Skipping user $($adUser.SamAccountName) because they do not have a UserPrincipalName." -ForegroundColor Yellow
        continue
    }

    $upn = $adUser.UserPrincipalName
    # Convert the GUID to a Base64 string, which is the required format for onPremisesImmutableId
    $immutableId = [System.Convert]::ToBase64String($adUser.objectGUID.ToByteArray())

    try {
        # --- Find the user in Azure AD by UPN and select the property to check ---
        Write-Host "Processing user: $upn"
        $azureUser = Get-MgUser -UserId $upn -Property 'id,userPrincipalName,onPremisesImmutableId' -ErrorAction Stop

        if ($azureUser) {
            # --- Check if onPremisesImmutableId is already set ---
            if ($azureUser.OnPremisesImmutableId) {
                if ($azureUser.OnPremisesImmutableId -eq $immutableId) {
                    Write-Host "  - onPremisesImmutableId for $upn is already correctly set." -ForegroundColor Cyan
                } else {
                    Write-Host "  - WARNING: User $upn already has a DIFFERENT onPremisesImmutableId set. Manual investigation is required." -ForegroundColor Yellow
                }
            } else {
                # --- Set the onPremisesImmutableId ---
                Write-Host "  - Setting onPremisesImmutableId for $upn..."
                # The body parameter for Update-MgUser is a hashtable of the properties to update
                $updateParams = @{
                    OnPremisesImmutableId = $immutableId
                }
                Update-MgUser -UserId $azureUser.Id -BodyParameter $updateParams
                Write-Host "  - Successfully set onPremisesImmutableId ($immutableId) for $upn." -ForegroundColor Green
            }
        }
    }
    <# catch [Microsoft.Graph.PowerShell.Models.Error.ODataError] {
        if ($_.Exception.Error.Code -eq 'Request_ResourceNotFound') {
             Write-Host "  - User with UPN $upn not found in Azure AD." -ForegroundColor Red
        } else {
            Write-Host "  - An OData error occurred for $upn : $($_.Exception.Error.Message)" -ForegroundColor Red
        }
    } #>
    catch {
        $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
        #we will catch any errors here and output them
        $ErrorMessage = $_.Exception.Message
        #Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
        Write-Host "The error on line # $errorLine is: $ErrorMessage  - An unexpected error occurred while processing $upn : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Script execution completed." -ForegroundColor Blue
# --- Disconnect from Microsoft Graph ---
Disconnect-MgGraph