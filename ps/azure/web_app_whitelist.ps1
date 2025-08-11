#this script will automatically generate the web app whitelists from the AD users and groups
#		it uses this AD group to find the members: InsertADGroupHere
#		and pulls the IP information from the Pager attribute on the Telephone tab
#Requires -Modules ActiveDirectory

Import-Module Az
Import-Module ActiveDirectory

clear

#functions
#logging function
function Output-Log {
 Param( 
        [alias("L")] 
        [string]$LogLevel, 
 
        [alias("M")] 
        [string]$msg
    ) 
	$date = Get-Date
	$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
}

function Add-Whitelist {
	Param(
		[array]$webapps
	)
	#now iterate through the output of the above commands and add the whitelists
	foreach ($webapp in $webapps) {
		Try {
			$AppServiceName = $webapp.name
			$ResourceGroupName = $webapp.ResourceGroupName
			$WebAppConfig = Get-AzResource -ResourceName $AppServiceName -ResourceType Microsoft.Web/sites/config -ResourceGroupName $ResourceGroupName -ApiVersion $APIVersion
			Output-Log -L "info" -M "Changing the whitelist for $AppServiceName."
			#delete all the existing whitelist entries
			$WebAppConfig.Properties.ipSecurityRestrictions = @()
			Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $APIVersion -Force | Out-Null
			
			#now add the new rules
			foreach ($NewIpRule in $NewIpRules) {
				 $WebAppConfig.Properties.ipSecurityRestrictions += $NewIpRule
			}
			Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $APIVersion -Force | Out-Null
		} Catch {
			$ErrorMessage = $_.Exception.Message
			Output-Log -L "ERROR" -M "The whitelist could not be loaded. The error is: $ErrorMessage"
			Exit 1
		}
	}
}

#globals
$priority = 100
#create the array
$NewIpRules = @()
$ResourceGroupName = ""
$AppServiceName = ""
$SubscriptionId = "InsertSubscriptionIDHere"

#Add static entries for the CHS and CC offices first
$offices = [ordered]@{ 
	"Office1"  = "255.255.255.255"
	"Office2" = "255.255.255.255"
	"Office3" = "255.255.255.255"
	"Office4" = "255.255.255.255"
}
foreach ($office in $offices.keys) {
	#add hashtable to array
	$NewIpRules += @{
		ipAddress = $offices[$office] + "/32"; 
		action = "Allow";
		priority = $priority;
		name = $office;
		description = "Created with the whitelist script";
		tag = "Default";
	}
	#increment the priority
	$priority++
}

Output-Log -L "info" -M "Getting user and IP information from AD."
#now add all the individual users info from AD
try {
	$devs = Get-ADGroupMember -Identity InsertADGroupHere | Sort-Object
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "The AD information could not be loaded. The error is: $ErrorMessage"
	Exit 1
}
foreach ($dev in $devs) {
	$user = get-aduser -Identity $dev -properties pager # | select samaccountname, Pager
	#we only want enabled accounts with the pager field populated
	if ($user.Pager -ne $null -And $user.enabled) {
		#add hashtable to array
			$NewIpRules += @{
				ipAddress = $user.Pager + "/32"; 
				action = "Allow";
				priority = $priority;
				name = $user.samaccountname;
				description = "Created with the whitelist script";
				tag = "Default";
			}
			#increment the priority
			$priority++
		}
}
$entries = $NewIpRules.length
Output-Log -L "info" -M "Config file built, adding $entries entries."

#borrowed code and ideas from here:
# https://swimburger.net/blog/azure/bulk-add-ip-access-restrictions-to-azure-app-service-using-az-powershell

#now feed the list of ip whitelists to the app services

#connect to azure
#If logged in, there's an azcontext, so we skip login
$context = get-azcontext
if($Null -eq $context){
    try {
		Login-AzAccount
	} Catch {
		$ErrorMessage = $_.Exception.Message
		Output-Log -L "ERROR" -M "Couldn't log into Azure. The error is: $ErrorMessage"
		Exit 1
	}
}

try {
	Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null

	#grab the latest available api version
	$APIVersion = ((Get-AzResourceProvider -ProviderNamespace Microsoft.Web).ResourceTypes | Where-Object ResourceTypeName -eq sites).ApiVersions[0]
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "Couldn't select the subscription or get the API version. The error is: $ErrorMessage"
	Exit 1
}

try {
	#get the list of web apps and their associated resource groups
	#dev
	$devwebapps = Get-AzResource -ResourceType "Microsoft.Web/sites" -name *dev* | select Name, ResourceGroupName
	#stage 
	$stagewebapps = Get-AzResource -ResourceType "Microsoft.Web/sites" -name *stage* | select Name, ResourceGroupName
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "Couldn't get the list of web apps. The error is: $ErrorMessage"
	Exit 1
}

#change to function so we can call the same code for dev and stage
Add-Whitelist $devwebapps
Add-Whitelist $stagewebapps

Output-Log -L "info" -M "Script complete."
