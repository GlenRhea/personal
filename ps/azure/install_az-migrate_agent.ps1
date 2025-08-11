#let's get the passphrase file from the migration appliance
#Set-Location "c:\ProgramData\ASR\home\svsystems\bin"
#.\genpassphrase.exe -v > MobSvc.passphrase

#the agent is located here:
#C:\ProgramData\ASR\home\svsystems\pushinstallsvc\repository

$installDir = "c:\temp"
if (!(Test-Path $installDir)) {
    New-Item -ItemType directory -Force -Path $installDir
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#now download the installer
Invoke-WebRequest 'https://hostingwebsite.com/Microsoft-ASR_UA_9.63.0.0_Windows_GA_21Oct2024_Release.exe' -OutFile "$installDir\MobilityServiceInstaller.exe"

Set-Location $installDir

#now copy the installation file to the server on c:\temp and the passphrase file you generated above
#then run these commands
#Rename-Item Microsoft-ASR_UA*Windows*release.exe MobilityServiceInstaller.exe
#Rename-Item -Path .\Microsoft-ASR_UA_9.63.0.0_Windows_GA_21Oct2024_Release.exe -NewName MobilityServiceInstaller.exe

#now extract the files
.\MobilityServiceInstaller.exe /q /x:C:\Temp\Extracted

Start-Sleep 5

Set-Location "c:\temp\extracted"

#install the agent
.\UnifiedAgent.exe /Role "MS" /InstallLocation "C:\Program Files (x86)\Microsoft Azure Site Recovery" /Platform "VmWare" /Silent /CSType CSLegacy

Set-Location "C:\Program Files (x86)\Microsoft Azure Site Recovery\agent"

#may have to run this to get the proper encoding with no whitespace
'6y5QLgrSFtCWD40U' | out-file C:\Temp\mobsvc_passphrase.txt -NoNewLine -encoding default

#now register the device
.\UnifiedAgentConfigurator.exe /CSEndPoint 192.168.122.102 /PassphraseFilePath C:\temp\mobsvc_passphrase.txt


