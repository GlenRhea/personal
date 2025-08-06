param (
   [string]$Module
)
#you will need to run this in ps5 and ps7 both as they use different module paths

#clear the screen first
#Clear-Host

. .\onb_audit_functions.ps1

Output-Log warn "Starting the Modules script!"
Output-Log info "Modules - Installing $Module module"

#if you get an unable to download error due to TLS settings, run this command
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#switching this to only install them as needed and not all on every machine
<# $Modules = @(
    
    "DomainHealthChecker",
    "SqlServer",
    "NTFSSecurity"
) #>
try {
    #adding these in to prevent prompts when adding modules, they do require admin rights though
    $null = Install-PackageProvider NuGet -Force
    $null = Set-PSRepository PSGallery -InstallationPolicy Trusted
} catch {
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "Modules - The error is: $ErrorMessage"
}


#Foreach($Module in $Modules){
    #Output-Log info "Modules - Checking on module: $Module"
    Try {
        if (!(Get-Module -ListAvailable -Name $Module)) {
            Output-Log warn "Modules - $Module isn't installed, installing it now"
            Install-Module $module -Scope AllUsers -Confirm:$False -Force -AllowClobber
            Output-Log info "Modules - $Module has been installed"
        } else {
            Output-Log info "Modules - $Module is already installed"
        }
        #modules needed for the onboarding scripts
        
    } catch {
        $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
        #we will catch any errors here and output them
        $ErrorMessage = $_.Exception.Message
        Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
    }

#}

#these are the requires you can put at the very top of a script to make sure
#you have the correct modules, ps version and if it needs to be ran as an admin
<#
#Requires -Version <N>[.<n>]
#Requires -Modules { <Module-Name> | <Hashtable> }
#Requires -PSEdition <PSEdition-Name>
#Requires -RunAsAdministrator
#>