#setup our vpn connections
$connexists = $true
#PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File \\server\temp$\Laptop_Apps\auto_install\scripts\setup_vpn_connections.ps1

#DR VPN - works great!
function SetupDRVPN {
	Set-VpnConnection -name "Company DR VPN" -TunnelType SSTP -AllUserConnection -Force -SplitTunneling $False -ServerAddress "vpnserver.cloudapp.net:51337" -AuthenticationMethod MSCHAPv2
	#import the cert
	$mypwd = ConvertTo-SecureString -String "passwordhere" -Force –AsPlainText
	$certpath = "\\server\archives$\FPserver\FPserver_Temp\Laptop_Apps\auto_install\installers\vpnserver.cloudapp.net.pfx"
	Import-PfxCertificate –FilePath $certpath cert:\localMachine\root -Password $mypwd
}

#check to see if the VPN connection exists
$conns = Get-VpnConnection -AllUserConnection
foreach ($conn in $conns) {
	echo  $conn[0].Name
	if ($conns.count -gt 0 -And $conn[0].Name.Contains("Company DR VPN")) {
		#change the vpn connection
		SetupDRVPN
		break
	} else {
		$connexists = $false
		#Add-VpnConnection -AllUserConnection -Name "Company DR VPN" -ServerAddress "8.8.8.8"
		#SetupDRVPN
	}
}

if (-Not $connexists) {
	Add-VpnConnection -AllUserConnection -Name "Company DR VPN" -ServerAddress "8.8.8.8"
	SetupDRVPN
}


function SetupVPN {
	Set-VpnConnection -name "Company VPN" -EncryptionLevel optional -AuthenticationMethod eap -AllUserConnection
	Set-VpnConnection -name "Company VPN" -TunnelType L2tp -L2tpPsk "presharedkeygoeshere" -AllUserConnection -Force -SplitTunneling $False -ServerAddress "ipaddyhere"
	Set-VpnConnection -name "Company VPN" -EncryptionLevel required -AllUserConnection
	#this throws the error, will need to open the connection manually and set the authentication method back to pap manually :(
	#Set-VpnConnection -name "Company VPN" -AllUserConnection -AuthenticationMethod pap
}

#check to see if the VPN connection exists
$conns = Get-VpnConnection -AllUserConnection
foreach ($conn in $conns) {
	echo  $conn[0].Name
	if ($conns.count -gt 0 -And $conn[0].Name.Contains("Company VPN")) {
		#change the vpn connection
		SetupVPN
		break
	} else {
		$connexists = $false
		#Add-VpnConnection -AllUserConnection -Name "Company DR VPN" -ServerAddress "8.8.8.8"
		#SetupDRVPN
	}
}

if (-Not $connexists) {
	Add-VpnConnection -AllUserConnection -Name "Company VPN" -ServerAddress "8.8.8.8"
	SetupVPN
}




#error
#Set-VpnConnection :  The current encryption selection requires EAP or MS-CHAPv2 logon security methods. PAP and CHAPdo not support Encryption settings 'Required' or 'Maximum'. : The parameter is incorrect.

#set dns alias
#Set-DnsClient -InterfaceAlias "Company VPN" -ConnectionSpecificSuffix "Company.local"

#set split tunnel routes
#Add-VpnConnectionRoute -ConnectionName "Company DR VPN" -DestinationPrefix "ipaddyhere/23"
#Add-VpnConnectionRoute -ConnectionName "Company DR VPN" -DestinationPrefix "ipaddyhere/26"
#Add-VpnConnectionRoute -ConnectionName "Company DR VPN" -DestinationPrefix "ipaddyhere/23"

#pause to see errors
#Write-Host "Press any key to continue ..."

#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "VPN Properties setup!"