@echo off
REM this script uninstalls and reinstalls all the company dll files

echo.

rem unregister
echo Uninstalling assemblies...
echo.
FOR  %%A IN ("c:\Referenced Assemblies\*.dll") DO (
	echo Uninstalling %%~nA
	"c:\Referenced Assemblies\gacutil\gacutil.exe" /u %%~nA /silent
)

echo.

rem register
echo Installing assemblies...
echo.
FOR  %%A IN ("c:\Referenced Assemblies\*.dll") DO (
	echo Installing "%%A"
	"c:\Referenced Assemblies\gacutil\gacutil.exe" /i "%%A" /silent
)

echo. 

rem verify installed
echo Verfying assemblies...
echo.
"c:\Referenced Assemblies\gacutil\gacutil.exe" /l|find "company"

pause