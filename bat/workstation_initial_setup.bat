@echo off
rem script to automatically install all the standard apps
cls
rem check to make sure we're in an elevated prompt
openfiles > NUL 2>&1 
if NOT %ERRORLEVEL% EQU 0 goto NotAdmin 
echo Good, it looks like you're running cmd as an admin...
echo.
rem make sure they deleted the computer from max rm
SET /P INPUT=Have you removed this computer from Max RM (if it was already there)? (y/n) 
echo.
IF /I '%INPUT%'=='y' GOTO Start
goto MaxRM

:Start
echo Alrighty then, let's get started!
echo.

rem misc setup stuff
call %CD%\scripts\workstation_initial_setup_misc.bat

rem installs
call %CD%\scripts\workstation_initial_setup_installs.bat

rem bitlocker
call %CD%\scripts\workstation_initial_setup_bitlocker.bat

echo This workstation has been setup, congrats!
echo.

:FinalCheck
SET /P INPUT=Have you checked the script for any informational messages or errors? (y/n) 
IF /I '%INPUT%'=='n' GOTO :FinalCheck
SET /P INPUT=Have you moved the computer to the workstation site on Max RM? (y/n) 
IF /I '%INPUT%'=='n' GOTO :FinalCheck
SET /P INPUT=Have you completed the VPN setup? (y/n) 
IF /I '%INPUT%'=='n' GOTO :FinalCheck
SET /P INPUT=Have you created the backup set (typically c:\users)? (y/n) 
IF /I '%INPUT%'=='n' GOTO :FinalCheck
echo.
goto :End

:NotAdmin 
echo Make sure you run this script as an administrator!
pause
exit 1

:MaxRM 
echo You have to remove this computer from Max RM first!
pause
exit 1

:End
echo Don't forget to run the OEM system updater!
pause
echo.
echo The system will now restart!
shutdown -r
exit 0