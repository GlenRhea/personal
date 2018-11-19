@echo off
rem this script will tell you which dc has the different fsmo roles in the domain

FOR  %%A IN (pdc rid infr name schema) do (
	echo Searching for the %%A role...
	dsquery server -hasfsmo %%A
	IF ERRORLEVEL 1 GOTO errorHandling
	)
	
IF ERRORLEVEL 1 GOTO errorHandling

exit 0

:errorHandling
echo There was an error!
exit 1

rem check replication command
rem repadmin /showrepl * /csv >showrepl.csv