@echo off
rem this script will enable bitlocker if it isn't already enabled and save the key in our standard location

rem check to see if the drive is already encrypted
manage-bde -status C:|find "Protection Off"  > NUL 2>&1 
if errorlevel 1 goto :Err

echo Enabling Bitlocker...
rem check to make sure we can access rxfp01 to save the recovery key
if exist "\\server\share\it\Documentation\Desktop\Bitlocker Keys" (
	manage-bde -on C: -rp -skiphardwaretest -UsedSpaceOnly > "\\server\share\it\Documentation\Desktop\Bitlocker Keys\%COMPUTERNAME%_bitlocker-key.txt" 
	echo Saved the recovery key to "\\server\share\it\Documentation\Desktop\Bitlocker Keys\%COMPUTERNAME%_bitlocker-key.txt"
) else (
	echo Unable to connect to \\server\share\it\Documentation\Desktop\Bitlocker Keys!
)

echo This script will stay running until the encryption has been completed, please wait...

rem put the script in an endless loop until the encryption has been finished
:CheckEncryption
echo|set /p=. 
ping -n 600 localhost > NUL 2>&1 
manage-bde -status C:|find "Protection On"  > NUL 2>&1 
if ERRORLEVEL 1 (
    goto :CheckEncryption
) else (
    echo Encryption Complete!
	 echo Please check the bitlocker key to make sure it was sucessfully created...
	 start /wait notepad "\\server\share\it\Documentation\Desktop\Bitlocker Keys\%COMPUTERNAME%_bitlocker-key.txt"
)
echo.

GOTO :End

:Err
echo The C: drive is already encrypted!
echo.

:End