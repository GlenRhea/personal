@echo off
cls
SETLOCAL ENABLEEXTENSIONS EnableDelayedExpansion
SET me=%~n0
SET workingdir=%~dp0

rem put script description and usage here

rem YYYYMMDD
set currdate=%date:~-4,4%%date:~-10,2%%date:~-7,2%
REM HHMMSS
set currtime=%time:~0,2%%time:~3,2%%time:~6,2%
set logfile=!me!_output-!currdate!_!currtime!.txt
echo %date% - %time% : "Starting the logshipping setup" > !logfile!
echo !workingdir!!logfile!

CALL :LOGGING "Checking prerequisites..."
rem commands here
IF ERRORLEVEL 1 GOTO errorHandling

:LOGGING
echo %date% - %time% : %1
echo.
rem add to log
echo %date% - %time% : %1 >> !logfile!
GOTO :EOF

:errorHandling
echo There was an error!
cscript //nologo D:\Scripts\send_email.vbs "Script %0 has failed!" "%0 was unable to reboot %1, check the logfiles for more information."
rem set body="%0 was unable to replicate ClientData, check the attached logfile (!logfile!) for more information."
rem cscript /nologo ls_send_email.vbs "Script %0 has failed!" !body! !workingdir!!logfile!
exit 1