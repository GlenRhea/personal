#references:
#http://newdelhipowershellusergroup.blogspot.com/2012/03/get-average-ping-response-time-of.html
#https://www.joakimnordin.com/is-it-possible-to-check-the-internet-performance-at-a-clients-network-using-powershell/
#http://woshub.com/get-external-ip-powershell/

#use this command to run the script
#copy script over using backstage, it will put the file in the path below
#cd to C:\Windows\Temp\ScreenConnect\ and then a numbered folder, whatever is the latest one and then a folder called Files
#PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File .\measure_network_speed.ps1

cls

$version = $PSVersionTable.PSVersion

Function Measure-NetworkSpeed{
    # The test file has to be a 10MB file for the math to work. If you want to change sizes, modify the math to match
    #$TestFile  = 'https://ftp.sunet.se/mirror/parrotsec.org/parrot/misc/10MB.bin'
	#$TestFile = 'https://southernscripts.net/downloads/LastPassInstaller.msi' 
    $TestFile = 'https://hostingwebsite.com/SSMS-Setup-ENU.exe'
    $TempFile  = Join-Path -Path $env:TEMP -ChildPath 'testfile.tmp'
    $WebClient = New-Object Net.WebClient
    $TimeTaken = Measure-Command { $WebClient.DownloadFile($TestFile,$TempFile) } | Select-Object -ExpandProperty TotalSeconds
    $SpeedMbps = (100 / $TimeTaken) * 8
    $Message = "{0:N2} Mbit/sec" -f ($SpeedMbps)
    echo "Speed: $Message"
}

#get machine name
echo "******** Machine Name ********"
hostname

#get public IP
echo "******** Public IP ********"
#nslookup myip.opendns.com. resolver1.opendns.com
$publicip = (Invoke-WebRequest -UseBasicParsing -uri "http://ifconfig.me/ip").Content
$publicip

#run a ping test
echo "******** Ping Test ********"
#Test-NetConnection -InformationLevel "Detailed"
#######################################
$CompName = "google.com","in-telecom.com","yahoo.com"
foreach ($comp in $CompName) {
       #the properties from test-connection have changed
		 if ($version.Major -gt "5") {
			#new
			$test = (Test-Connection -ComputerName $comp -Count 20  | measure-Object -Property Latency -Average).average
		} else {
		 #old
			$test = (Test-Connection -ComputerName $comp -Count 20  | measure-Object -Property "ResponseTime" -Average).average
		}
       $response = ($test -as [int] )
       write-Host "The Average response time for" -ForegroundColor Green -NoNewline;write-Host " `"$comp`" is " -ForegroundColor Red -NoNewline;;Write-Host "$response ms" -ForegroundColor Black -BackgroundColor white
}
##########################################

echo "******** Discarded or Error Packets ********"
$adapter = (Get-NetAdapter -physical | where status -eq 'up').Name
$netinfo = Get-NetAdapterStatistics -Name $adapter
#Get-NetAdapterStatistics -Name $adapter | Format-List -Property "*"
$InterfaceDescription = $netinfo.InterfaceDescription
echo "InterfaceDescription : $InterfaceDescription"
$name = $netinfo.Name
echo "Name : $name"
$OutboundDiscardedPackets = $netinfo.OutboundDiscardedPackets
echo "OutboundDiscardedPackets : $OutboundDiscardedPackets"
$OutboundPacketErrors = $netinfo.OutboundPacketErrors
echo "OutboundPacketErrors : $OutboundPacketErrors"
$ReceivedDiscardedPackets = $netinfo.ReceivedDiscardedPackets
echo "ReceivedDiscardedPackets : $ReceivedDiscardedPackets"
$ReceivedPacketErrors = $netinfo.ReceivedPacketErrors
echo "ReceivedPacketErrors : $ReceivedPacketErrors"



echo "******** Speed Test ********"
Measure-NetworkSpeed

#get geoip information
echo "******** GeoIP ********"
$city = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/city')
$city = $city.trim()
$region = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/region')
$region = $region.trim()
$country = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/country')
$country = $country.trim()
$postal = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/postal')
#$postal = $postal.trim()
$hostname = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/hostname')
$hostname = $hostname.trim()
$isp = Invoke-RestMethod -Uri ('http://ipinfo.io/'+$publicip+'/org')
$isp = $isp.trim()
echo "Hostname: $hostname"
echo "ISP: $isp"
echo "Location: $city, $region, $postal, $country"
