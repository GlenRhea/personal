@echo off
REM ~ echo Setting up the VPN connections...

rem delete any existing desktop shortcuts first
FOR  %%A IN ("c:\users\public\desktop\Company VPN.lnk", "c:\users\public\desktop\Company DR VPN.lnk", c:\users\public\desktop\RxR_VPN.lnk, c:\users\public\desktop\RxR_DR_VPN.lnk) do (
	if exist %%A echo Deleting existing link %%A && del %%A
)

rem create the batch files first
echo @echo off > c:\temp\vpn.bat
echo start /min c:\temp\vpn1.bat %%1 >> c:\temp\vpn.bat

echo @echo off > c:\temp\vpn1.bat
echo rem this script will connect or disconnect the appropriate VPN connection >> c:\temp\vpn1.bat
echo ipconfig^|find /i %%1 ^&^& rasphone -h %%1  ^|^| rasphone -d %%1 >> c:\temp\vpn1.bat
echo rem create a shortcut to: vpn.bat "Name Of The Connection" >> c:\temp\vpn1.bat
echo exit 1 >> c:\temp\vpn1.bat

rem create a shortcut to: vpn.bat "Name Of The Connection" on the public desktop
rem create the regular VPN connection first
set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = "%PUBLIC%\Desktop\RxR_VPN.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "%SYSTEMDRIVE%\temp\vpn.bat" >> %SCRIPT%
echo oLink.Arguments  = """Company VPN""" >> %SCRIPT%
echo oLink.WorkingDirectory ="%SYSTEMDRIVE%\Program Files" >> %SCRIPT%
echo oLink.IconLocation = "imageres.dll, 20" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%
cscript /nologo %SCRIPT%
del %SCRIPT%
rem create the DR VPN connection now
set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = "%PUBLIC%\Desktop\RxR_DR_VPN.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "%SYSTEMDRIVE%\temp\vpn.bat" >> %SCRIPT%
echo oLink.Arguments  = """Company DR VPN""" >> %SCRIPT%
echo oLink.WorkingDirectory ="%SYSTEMDRIVE%\Program Files" >> %SCRIPT%
echo oLink.IconLocation = "imageres.dll, 20" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%
cscript /nologo %SCRIPT%
del %SCRIPT%

echo VPN desktop shortcuts created!
echo.