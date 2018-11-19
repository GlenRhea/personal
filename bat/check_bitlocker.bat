@echo off
rem this script checks to see if bitlocker is enabled on C:

manage-bde -status C:|find "Protection On" > NUL
IF ERRORLEVEL 1 GOTO :ERR
echo Enabled on C:
GOTO :EXIT

:ERR
echo Script check failed!
exit 1001

:EXIT
exit 0