@echo off
rem misc setup steps

echo Setting up the VPN connections...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File %CD%\scripts\setup_vpn_connections.ps1
call %CD%\scripts\setup_vpn_shortcuts.bat
echo.
rem delete the vpn setup powershell file since it has the PSK's in it
if exist %CD%\scripts\setup_vpn_connections.ps1 del %CD%\scripts\setup_vpn_connections.ps1

echo Adding the VPN registry entry...
reg import %CD%\installers\azure_vpn_809_fix.reg

:VPN
echo VPN setup not complete! Double click the desktop icon RxR_VPN and then click Properties.
echo Security tab - Authentication - Check "Allow these protocols" - Check Unencrypted password (PAP) and uncheck any of the other options
echo NOTE: This only needs to be done on the "CompanyX VPN" connection!
echo.
rem make sure they deleted the computer from max rm
SET /P INPUT=Have you completed the VPN setup? (y/n) 
echo.
IF /I '%INPUT%'=='y' GOTO Start
goto VPN
:Start

echo Copying the MemberServices folder...
if not exist c:\Users\Public\Desktop\MemberServices mkdir c:\Users\Public\Desktop\MemberServices
xcopy %CD%\scripts\MemberServices c:\Users\Public\Desktop\MemberServices /e /q /y
echo.

echo Setting up wifi connections...
rem delete any existing profiles first
FOR  %%A IN (Guest, Remote, Internal, Hotspot) do (
	netsh wlan delete profile "CompanyX %%A"
)
echo.
FOR  %%A IN (Hotspot, Remote, Guest, Internal) do (
	netsh wlan add profile filename="%CD%\scripts\wifi_settings\Wi-Fi-CompanyX %%A.xml" user=all
)
echo.

echo Deleting the wifi profiles...
rmdir /s /q %CD%\scripts\wifi_settings
echo.

