@echo off

rem make sure they have created the backup account first!
:CreateBackup
SET /P INPUT=Have you created the backup account yet? (y/n) 
echo.
IF /I '%INPUT%'=='n' GOTO :CreateBackup

SET /P pw=Please enter the password for the backup account: 
set /p acct=Please enter the account NUMBER for the backup account you just created (ex. 0027): 
echo Installing the Backup Agent...
start /wait %CD%\installers\ManagedBackup-Setup.exe /Username=user /Password=%pw% /ComputerID=%acct% /ManagedKey /Silent /SuppressMsgBoxes /VerySilent
rem clear the password
set pw=""
echo.

rem software installs
echo Installing Meraki MDM Client...
start /wait msiexec /quiet /passive /I /norestart %CD%\installers\MerakiSM-Agent-systems-manager.msi
echo.

echo Installing Google Chrome...
start /wait msiexec /quiet /passive /I /norestart %CD%\installers\googlechromestandaloneenterprise.msi
echo.

echo Installing FireFox...
start /wait msiexec /quiet /passive /I /norestart %CD%\installers\Firefox-45.0.1-en-US.msi
echo.

echo Installing Adobe Reader...
start /wait msiexec /quiet /passive /I /norestart %CD%\installers\AcroRdrDC1500720033_en_US.msi
echo.

echo Installing Java...
start /wait %CD%\installers\jre-8u91-windows-i586.exe INSTALLCFG=%CD%\installers\install_java.cfg
echo.

echo Installing MaxFocus Agent...
start /wait %CD%\installers\MaxFocus_AGENT_RW.EXE
echo The computer will be put in the barebones site by default. Move it to the workstations site after everything is done installing.
echo.

echo Installing Office 2016...
start /wait %CD%\installers\Setup.X86.en-us_O365ProPlusRetail_be55fe3a-0696-495c-87c2-c5b1a66cc188_TX_PR_b_32_.exe
echo.

echo Installing OEM updater...
rem looks for the manufacturer and installs the updater for that OEM
systeminfo|find /i "lenovo" > NUL 2>&1 && start /wait %CD%\installers\systemupdate507-2016-01-13.exe  /verysilent /norestart || start /wait %CD%\installers\Systems-Management_Application_4DP6N_WN32_2.1.1_A00.EXE /s
rem pause a bit before creating the desktop shortcuts
ping -n 20 localhost > NUL 2>&1 
echo Creating desktop shortcut for the OEM updater...
if exist "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Lenovo\System Update.lnk" copy "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Lenovo\System Update.lnk" c:\users\public\desktop
if exist "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Command Update\Dell Command Update.lnk" copy "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Command Update\Dell Command Update.lnk" c:\users\public\desktop
echo.
