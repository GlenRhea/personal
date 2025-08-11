#script to get computers with service accounts that need to have the passwords changed
#Get-WmiObject win32_service -computername rxdc01 | Format-Table displayname, startname, startmode
$servers = "server1, server2"

#check services for SA passwords to change
foreach ($server in $servers) {
	#$services = Get-WmiObject win32_service
	$services = Get-WmiObject win32_service -computername $server
	foreach ($service in $services) {
		#echo $service.startname
 		if ($service.startname -And ($service.startname.Contains("accountname") -Or $service.startname.Contains("sa_"))) {
 			echo "$server,$($service.displayname),$($service.startname)"
 		}
	}
}