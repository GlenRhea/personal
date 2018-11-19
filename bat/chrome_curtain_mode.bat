@echo off
rem batch file to setup chrome remote desktop curtain mode on W10

rem add the registry entries

rem for the curtain mode
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome" /v RemoteAccessHostRequireCurtain /t REG_DWORD /d 1
rem to allow connections via RDP
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 1
rem enable RDP
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
rem disable NLA
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v UserAuthentication /t REG_DWORD /d 0 /f

rem reboot
shutdown -r now