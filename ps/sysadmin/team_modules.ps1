#you will need to run this in ps5 and ps7 both as they use different module paths
#you DO NOT need to run this as admin and shouldn't anyways since we're putting them 
#in our local profile

#clear the screen first
Clear-Host

#adding these in to prevent prompts when adding modules, they do require admin rights though
#Install-PackageProvider NuGet -Force;
#Set-PSRepository PSGallery -InstallationPolicy Trusted

#if you get an unable to download error due to TLS settings, run this command
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Modules = @(

    "AZ",
    "ActiveDirectory",
    "ExchangeOnlineManagement",
    "ImportExcel",
    "Microsoft.Graph",
    "Microsoft.Online.SharePoint.PowerShell",
    "PnP.PowerShell",
    "MicrosoftTeams",
    "Microsoft365DSC",
    "AzureAD",
    "PNP.PowerShell",
    "DCToolbox",
    "UniversalPrintManagement"
)

Foreach($Module in $Modules){

    Try{
        #we're going to install these as the current user which will put them on your onedrive
        #if you run a script from another computer that you've signed into onedrive it should pick 
        #them up and download them from onedrive for you.
        #be careful though because some modules/code require a version matrix between the ps version and module versions
        Install-Module $module -Scope CurrentUser -Confirm:$False -Force
    }Catch{
        write-host "Error Installing $module `n : $_ `n `n"
    }

}

#these are the requires you can put at the very top of a script to make sure
#you have the correct modules, ps version and if it needs to be ran as an admin
<#
#Requires -Version <N>[.<n>]
#Requires -Modules { <Module-Name> | <Hashtable> }
#Requires -PSEdition <PSEdition-Name>
#Requires -RunAsAdministrator
#>