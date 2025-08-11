#this script cleans up abandoned universal print connectors
#install the module if you don't have it already
#$module = "UniversalPrintManagement"
#Install-Module $module -Scope CurrentUser -Confirm:$False -Force

Connect-UPService -UserPrincipalName "user@company.com"

$connectors = Get-UPConnector

foreach ($connector in $connectors) {
    Remove-UPConnector -connectorid $connector
}
