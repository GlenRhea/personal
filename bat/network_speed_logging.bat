@ECHO OFF

REM network transfer logging script
REM get date
for /f "tokens=2 delims= " %%a in ('date /t') do (set odate=%%a)

for /f "tokens=1-2 delims=  " %%a in ('time /t') do (set otime=%%a%%b)

echo %otime% ^| %odate%
