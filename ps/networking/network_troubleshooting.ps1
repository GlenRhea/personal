#script to help with network troubleshooting class
#the actual commands are preceded by this:
#command

function Output-Log {
    Param( 
           [Parameter(Mandatory)]
           [ValidateSet('info','warn', 'error')]
           [alias("L")] 
           [string]$LogLevel, 
    
           [alias("M")] 
           [string]$msg
       ) 
       $date = Get-Date
       #$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       $output = $date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       switch ($LogLevel) {
           warn { Write-Host -ForegroundColor Yellow $output}
           error { Write-Host -ForegroundColor Red $output}
           Default { Write-Host -ForegroundColor Green $output }
    }
}

#show ipconfig options
Output-Log -L "info" -M "ipconfig section"
Output-Log -L "info" -M "ipconfig /all"
#command
ipconfig /all
#only in cmd
Output-Log -L "info" -M "ipconfig /release && ipconfig /renew (cmd only)"
Output-Log -L "info" -M "ipconfig /flushdns && nbtstat -RR (cmd only)"
Read-Host -Prompt "Press enter to continue..."
Clear-Host

#check connectivity
#ping gateway
Output-Log -L "info" -M "Ping section"
Output-Log -L "info" -M "Ping gateway"
Output-Log -L "info" -M "ping 192.168.0.1"
#command
ping 192.168.0.1
Read-Host -Prompt "Press enter to continue..."
Output-Log -L "info" -M "Ping internet by IP"
Output-Log -L "info" -M "ping 8.8.8.8"
#command
ping 8.8.8.8
Read-Host -Prompt "Press enter to continue..."
Output-Log -L "info" -M "Ping internet by DNS"
Output-Log -L "info" -M "ping google.com"
#command
ping google.com
Read-Host -Prompt "Press enter to continue..."
Clear-Host

Output-Log -L "info" -M "Testing TCP connect"
Output-Log -L "info" -M "Test-NetConnection google.com -CommonTCPPort HTTP"
#command
Test-NetConnection google.com -CommonTCPPort HTTP
Read-Host -Prompt "Press enter to continue..."
Output-Log -L "warn" -M "Testing TCP connect, this one should fail..."
Output-Log -L "warn" -M "Test-NetConnection google.com -port 22"
#command
Test-NetConnection google.com -port 22
Read-Host -Prompt "Press enter to continue..."

#get public IP
Output-Log -L "info" -M "Get public IP"
Output-Log -L "info" -M "nslookup myip.opendns.com. resolver1.opendns.com"
#or
Output-Log -L "info" -M "(Invoke-WebRequest -UseBasicParsing -uri `"http://ifconfig.me/ip`").Content"
#command
(Invoke-WebRequest -UseBasicParsing -uri "http://ifconfig.me/ip").Content
#you may have to use the first method on older devices
Read-Host -Prompt "Press enter to continue..."
Clear-Host

#more advanced network troubleshooting
#show all listening/established ports, powershell commands
Output-Log -L "info" -M "Show all established connections"
Output-Log -L "info" -M "netstat -ano | findstr `"EST`""
#command
netstat -ano | findstr "EST"
Read-Host -Prompt "Press enter to continue..."
Clear-Host
Output-Log -L "info" -M "Show all listening ports"
Output-Log -L "info" -M "netstat -ano | findstr `"LIST`""
#command
netstat -ano | findstr "LIST"
Read-Host -Prompt "Press enter to continue..."
Clear-Host

#check dns
Output-Log -L "info" -M "DNS lookup"
Output-Log -L "info" -M "nslookup google.com"
#command
nslookup google.com
Read-Host -Prompt "Press enter to continue..."
Clear-Host

#routes
Output-Log -L "info" -M "Print routes"
Output-Log -L "info" -M "route print"
#command
route print
Read-Host -Prompt "Press enter to continue..."
Clear-Host

#arp table
Output-Log -L "info" -M "Print arp table"
Output-Log -L "info" -M "arp -a -v"
#command
arp -a -v
Read-Host -Prompt "Press enter to continue..."
Clear-Host