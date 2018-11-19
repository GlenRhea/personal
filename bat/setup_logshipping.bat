@echo off
cls
SETLOCAL ENABLEEXTENSIONS EnableDelayedExpansion
SET me=%~n0
SET workingdir=%~dp0
rem YYYYMMDD
set currdate=%date:~-4,4%%date:~-10,2%%date:~-7,2%
REM HHMMSS
set currtime=%time:~0,2%%time:~3,2%%time:~6,2%

rem globals
set monitor=monitorserver
set starttime=%date% %time%
set logfile=!me!_output-!currdate!_!currtime!.txt
rem setup logfile
echo %date% - %time% : "Starting the logshipping setup" > !logfile!

SET /P db=What database do you want to setup logshipping for? (DB1, DB2, etc) 
SET /P environ=What environment is this? (dev or prod) 
echo.
IF /I '%environ%'=='dev' GOTO :DEV
IF /I '%environ%'=='prod' GOTO :PROD
GOTO :END

:DEV
set primary=server1
set secondary=server2
set backuppath=F:\SQLBackups\!db!
set primlogshippath=F:\logshipping\
set seclogshippath=I:\logshipping\
set restorepath=I:\temp\
set secondarydatapath=F:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\
set secondarylogpath=G:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\
set secondarybackuppath=J:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\
GOTO :START
:PROD
rem commented out just in case!
set primary=server1
set secondary=server2
set backuppath=F:\temp
set primlogshippath=F:\logshipping\
set seclogshippath=N:\LogShipping\
set restorepath=J:\DBRestore\
set secondarydatapath=L:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\
set secondarylogpath=K:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\
set secondarybackuppath=N:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\!db!\

REM setup logshipping
:START
CALL :LOGGING "Checking prerequisites..."
rem check to see if the servers are online
	ping -n 1 !primary! >nul: 2>nul:
	IF ERRORLEVEL 1 CALL :LOGGING "!primary! is not online!" & GOTO :END
	ping -n 1 !secondary! >nul: 2>nul:
	IF ERRORLEVEL 1 CALL :LOGGING "!secondary! is not online!" &  GOTO :END
	ping -n 1 !monitor! >nul: 2>nul:
	IF ERRORLEVEL 1 CALL :LOGGING "!monitor! is not online!" & GOTO :END
rem since the servers are online...
if not exist c:\windows\system32\psexec.exe CALL :LOGGING "ERROR: c:\windows\system32\psexec.exe not found on the local machine!" && GOTO :END
if not exist "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\sqlcmd.exe" CALL :LOGGING "ERROR:  "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\sqlcmd.exe" not found on the localmachine!" && GOTO :END
psexec -accepteula \\!primary! cmd /c "if not exist "C:\Program Files\WinRAR\Rar.exe" exit 1" > NUL 2>&1  || CALL :LOGGING "ERROR:  C:\Program Files\WinRAR\Rar.exe not found on !primary!." && GOTO :END
psexec -accepteula \\!secondary! cmd /c "if not exist "C:\Program Files\WinRAR\Rar.exe" exit 1" > NUL 2>&1   || CALL :LOGGING "ERROR:  C:\Program Files\WinRAR\Rar.exe not found on !secondary!." && GOTO :END
psexec -accepteula \\!primary! cmd /c "if not exist "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe" exit 1" > NUL 2>&1   || CALL :LOGGING "ERROR:  C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe not found on !primary!." && GOTO :END
	
CALL :LOGGING "Everything looks good, let's begin."

CALL :LOGGING "Setting up logshipping for !db! with !primary! as the primary and !secondary! as the secondary."
pause
echo.

CALL :LOGGING "Removing the old log shipping config, if it exists..."
	sqlcmd -S !primary! -Q "EXEC MASTER.dbo.sp_delete_log_shipping_primary_secondary @primary_database = N'!db!',@secondary_server = N'!secondary!',@secondary_database = N'!db!'" >> !logfile! 2>&1
	sqlcmd -S !primary! -Q "EXEC MASTER.dbo.sp_delete_log_shipping_primary_database @database = N'!db!'" >> !logfile! 2>&1
	sqlcmd -S !secondary! -Q "EXEC MASTER.dbo.sp_delete_log_shipping_secondary_database @secondary_database = N'!db!'" >> !logfile! 2>&1
	sqlcmd -S !monitor! -Q "set nocount on;DELETE FROM msdb.dbo.log_shipping_monitor_primary WHERE primary_server = '!primary!' AND primary_database = '!db!'"  >> !logfile! 2>&1
	sqlcmd -S !monitor! -Q "set nocount on;DELETE FROM msdb.dbo.log_shipping_monitor_secondary WHERE  secondary_server = '!secondary!' AND secondary_database = '!db!'"  >> !logfile! 2>&1

CALL :LOGGING "Delete secondary database, if it exists..."
	sqlcmd -S !secondary! -Q "IF EXISTS ( SELECT [name] FROM sys.databases WHERE [name] = '!db!' ) DROP database !db!" >> !logfile! 2>&1

CALL :LOGGING "Deleting the existing backup file, if it exists..."
	psexec -accepteula \\!primary! cmd /c "if exist !backuppath!\!db!.bak del !backuppath!\!db!.bak" >> !logfile! 2>&1

CALL :LOGGING "Creating the backup file..."
	sqlcmd -S !primary! -Q "BACKUP DATABASE !db! TO disk = '!backuppath!\!db!.bak'" >> !logfile! 2>&1
	
CALL :LOGGING "Deleting the existing compressed backup file, if it exists..."
	psexec -accepteula \\!primary! cmd /c "if exist !backuppath!\!db!.rar del !backuppath!\!db!.rar" >> !logfile! 2>&1

CALL :LOGGING "Compressing the backup file..."
	psexec -accepteula \\!primary! "C:\Program Files\WinRAR\Rar.exe" a -ep -m5 !backuppath!\!db!.rar !backuppath!\!db!.bak >> !logfile! 2>&1

CALL :LOGGING "Deleting backup file from azure storage..."
	psexec -accepteula \\!secondary! cmd /c "net use y: \\serverstorage.file.core.windows.net\restoredb LgXR2gob73kw466W7FNBzREDgrnwKv1u2BYYHKdi4JWHr9Xcy0cMRLsVpdm9zVu8LzIzXMxdewkLRlFGfctEBQ== /user:serverstorage && del /F /Q y:\!db!.rar && net use y: /delete" >> !logfile! 2>&1

CALL :LOGGING "Copying backup file to azure storage..."
	psexec -accepteula \\!primary! "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe" /Y /source:!backuppath! /dest:https://serverstorage.file.core.windows.net/restoredb /destkey:"/destkeyhere" /pattern:!db!.rar /NC:4  >> !logfile! 2>&1

CALL :LOGGING "Copying backup file from azure storage to azure VM..."
	psexec -accepteula \\!secondary! cmd /c "net use y: \\serverstorage.file.core.windows.net\restoredb destkeyhere== /user:serverstorage && copy /y y:\!db!.rar !restorepath! && net use y: /delete" >> !logfile! 2>&1

CALL :LOGGING "Decompressing backup file..."
	psexec -accepteula \\!secondary! "C:\Program Files\WinRAR\unRar.exe" e -y !restorepath!\!db!.rar !restorepath!\ >> !logfile! 2>&1

CALL :LOGGING "Restoring the backup file..."
	GOTO :RESTORE
	:STARTRESTORE
	sqlcmd -S !secondary! -i restore.sql >> !logfile! 2>&1

CALL :LOGGING "Deleting the old trn files, if they exist..."
	psexec -accepteula \\!primary! cmd /c "del /F /Q !primlogshippath!\*!db!*"  >> !logfile! 2>&1
	psexec -accepteula \\!secondary! cmd /c "del /F /Q !seclogshippath!\*!db!*"  >> !logfile! 2>&1

CALL :LOGGING "Creating new log shipping configuration..."
	rem create the sql files first
	GOTO :PRIMARYADD
	:STARTLOGSHIP
	sqlcmd -S !primary! -i primaryadd.sql >> !logfile! 2>&1
	sqlcmd -S !secondary! -i secondaryadd.sql >> !logfile! 2>&1
	rem need the ids of the newly added logshipping configs
	for /f "delims=" %%i in ('sqlcmd -h -1 -S !primary! -Q "set nocount on;select primary_id from msdb.dbo.log_shipping_primary_databases where primary_database = '!db!'"') do set primary_id=%%i
	for /f "delims=" %%i in ('sqlcmd -h -1 -S !secondary! -Q "set nocount on;select secondary_id FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = '!db!'"') do set secondary_id=%%i
	GOTO :MONITORADD
	:MONITORSTART
	sqlcmd -S !monitor! -i primarymonitoradd.sql >> !logfile! 2>&1
	sqlcmd -S !monitor! -i secondarymonitoradd.sql >> !logfile! 2>&1

CALL :LOGGING "Cleaning up..."
	del /F /Q primaryadd.sql >> !logfile! 2>&1
	del /F /Q secondaryadd.sql >> !logfile! 2>&1
	del /F /Q primarymonitoradd.sql >> !logfile! 2>&1
	del /F /Q secondarymonitoradd.sql >> !logfile! 2>&1
	del /F /Q restore.sql >> !logfile! 2>&1

set endtime=%date% %time%

CALL :LOGGING "This script was started on !starttime! and completed on !endtime!"
CALL :LOGGING "Please check the log file for any errors: !logfile!"

CALL :LOGGING "Sending email..."
	set body="Set up logshipping for !db! with !primary! as the primary and !secondary! as the secondary. ^ This script was started on !starttime! and completed on !endtime! ^ Please check the log file for any errors: !logfile!"
	cscript /nologo ls_send_email.vbs "Completed Logshipping Setup" !body! !workingdir!!logfile! 

GOTO :END

:RESTORE
echo USE [master] > restore.sql
echo RESTORE DATABASE [!db!] FROM  DISK = N'!restorepath!\!db!.bak' >> restore.sql
echo WITH  FILE = 1,   >> restore.sql
echo MOVE N'!db!' TO N'!secondarydatapath!\!db!.mdf',   >> restore.sql
echo MOVE N'!db!_log' TO N'!secondarylogpath!\!db!_1.ldf',   >> restore.sql
echo STANDBY = N'!secondarybackuppath!\!db!_RollbackUndo_!currdate!_!currtime!.bak',   >> restore.sql
echo NOUNLOAD,  STATS = 5 >> restore.sql
echo GO >> restore.sql
GOTO :STARTRESTORE

:PRIMARYADD
echo -- ****** Begin: Script to be run at Primary: [!primary!] ****** > primaryadd.sql
echo use master >> primaryadd.sql
echo DECLARE @LS_BackupJobId	AS uniqueidentifier >> primaryadd.sql
echo DECLARE @LS_PrimaryId	AS uniqueidentifier >> primaryadd.sql
echo DECLARE @SP_Add_RetCode	As int  >> primaryadd.sql
echo EXEC @SP_Add_RetCode = master.dbo.sp_add_log_shipping_primary_database >> primaryadd.sql
echo 		@database = N'!db!' >> primaryadd.sql
echo 		,@backup_directory = N'F:\LogShipping' >> primaryadd.sql
echo 		,@backup_share = N'\\!primary!\LogShipping' >> primaryadd.sql
echo 		,@backup_job_name = N'LSBackup_!db!' >> primaryadd.sql
echo 		,@backup_retention_period = 4320 >> primaryadd.sql
echo 		,@backup_compression = 2 >> primaryadd.sql
echo 		,@monitor_server = N'!monitor!'  >> primaryadd.sql
echo 		,@monitor_server_security_mode = 1  >> primaryadd.sql
echo 		,@backup_threshold = 60  >> primaryadd.sql
echo 		,@threshold_alert_enabled = 1 >> primaryadd.sql
echo 		,@history_retention_period = 5760  >> primaryadd.sql
echo 		,@backup_job_id = @LS_BackupJobId OUTPUT  >> primaryadd.sql
echo 		,@primary_id = @LS_PrimaryId OUTPUT  >> primaryadd.sql
echo 		,@overwrite = 1  >> primaryadd.sql
echo 		,@ignoreremotemonitor = 1  >> primaryadd.sql

echo IF (@@ERROR = 0 AND @SP_Add_RetCode = 0)  >> primaryadd.sql
echo BEGIN  >> primaryadd.sql

echo DECLARE @LS_BackUpScheduleUID	As uniqueidentifier  >> primaryadd.sql
echo DECLARE @LS_BackUpScheduleID	AS int  >> primaryadd.sql

echo EXEC msdb.dbo.sp_add_schedule  >> primaryadd.sql
echo 		@schedule_name =N'LSBackupSchedule_!primary!1'  >> primaryadd.sql
echo 		,@enabled = 1  >> primaryadd.sql
echo 		,@freq_type = 4  >> primaryadd.sql
echo 		,@freq_interval = 1  >> primaryadd.sql
echo 		,@freq_subday_type = 4  >> primaryadd.sql
echo 		,@freq_subday_interval = 15  >> primaryadd.sql
echo 		,@freq_recurrence_factor = 0  >> primaryadd.sql
echo 		,@active_start_date = 20160607  >> primaryadd.sql
echo 		,@active_end_date = 99991231  >> primaryadd.sql
echo 		,@active_start_time = 0  >> primaryadd.sql
echo 		,@active_end_time = 235900  >> primaryadd.sql
echo 		,@schedule_uid = @LS_BackUpScheduleUID OUTPUT  >> primaryadd.sql
echo 		,@schedule_id = @LS_BackUpScheduleID OUTPUT  >> primaryadd.sql

echo EXEC msdb.dbo.sp_attach_schedule  >> primaryadd.sql
echo 		@job_id = @LS_BackupJobId  >> primaryadd.sql
echo 		,@schedule_id = @LS_BackUpScheduleID   >> primaryadd.sql

echo EXEC msdb.dbo.sp_update_job  >> primaryadd.sql
echo 		@job_id = @LS_BackupJobId  >> primaryadd.sql
echo 		,@enabled = 1  >> primaryadd.sql

echo END  >> primaryadd.sql

echo EXEC master.dbo.sp_add_log_shipping_primary_secondary   >> primaryadd.sql
echo		@primary_database = N'!db!'   >> primaryadd.sql
echo		,@secondary_server = N'!secondary!'   >> primaryadd.sql
echo		,@secondary_database = N'!db!'   >> primaryadd.sql
echo		,@overwrite = 1   >> primaryadd.sql

:SECONDARYADD
echo -- ****** Begin: Script to be run at Secondary: [!secondary!] ******  > secondaryadd.sql
echo USE MSDB >> secondaryadd.sql
echo DECLARE @LS_Secondary__CopyJobId	AS uniqueidentifier   >> secondaryadd.sql
echo DECLARE @LS_Secondary__RestoreJobId	AS uniqueidentifier   >> secondaryadd.sql
echo DECLARE @LS_Secondary__SecondaryId	AS uniqueidentifier   >> secondaryadd.sql
echo DECLARE @LS_Add_RetCode	As int   >> secondaryadd.sql

echo EXEC @LS_Add_RetCode = master.dbo.sp_add_log_shipping_secondary_primary   >> secondaryadd.sql
echo		@primary_server = N'!primary!'   >> secondaryadd.sql
echo		,@primary_database = N'!db!'   >> secondaryadd.sql
echo		,@backup_source_directory = N'\\!primary!\LogShipping'   >> secondaryadd.sql
echo		,@backup_destination_directory = N'\\!secondary!\LogShipping'   >> secondaryadd.sql
echo		,@copy_job_name = N'LSCopy_!primary!_!db!'   >> secondaryadd.sql
echo		,@restore_job_name = N'LSRestore_!primary!_!db!'   >> secondaryadd.sql
echo		,@file_retention_period = 4320   >> secondaryadd.sql
echo		,@monitor_server = N'!monitor!'   >> secondaryadd.sql
echo		,@monitor_server_security_mode = 1   >> secondaryadd.sql
echo		,@overwrite = 1   >> secondaryadd.sql
echo		,@copy_job_id = @LS_Secondary__CopyJobId OUTPUT   >> secondaryadd.sql
echo		,@restore_job_id = @LS_Secondary__RestoreJobId OUTPUT   >> secondaryadd.sql
echo		,@secondary_id = @LS_Secondary__SecondaryId OUTPUT  >> secondaryadd.sql

echo IF (@@ERROR = 0 AND @LS_Add_RetCode = 0)  >> secondaryadd.sql
echo BEGIN  >> secondaryadd.sql

echo DECLARE @LS_SecondaryCopyJobScheduleUID	As uniqueidentifier  >> secondaryadd.sql
echo DECLARE @LS_SecondaryCopyJobScheduleID	AS int  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_add_schedule  >> secondaryadd.sql
echo		@schedule_name =N'DefaultCopyJobSchedule'  >> secondaryadd.sql
echo		,@enabled = 1  >> secondaryadd.sql
echo		,@freq_type = 4  >> secondaryadd.sql
echo		,@freq_interval = 1  >> secondaryadd.sql
echo		,@freq_subday_type = 4  >> secondaryadd.sql
echo		,@freq_subday_interval = 15  >> secondaryadd.sql
echo		,@freq_recurrence_factor = 0  >> secondaryadd.sql
echo		,@active_start_date = 20160607  >> secondaryadd.sql
echo		,@active_end_date = 99991231  >> secondaryadd.sql
echo		,@active_start_time = 0  >> secondaryadd.sql
echo		,@active_end_time = 235900  >> secondaryadd.sql
echo		,@schedule_uid = @LS_SecondaryCopyJobScheduleUID OUTPUT  >> secondaryadd.sql
echo		,@schedule_id = @LS_SecondaryCopyJobScheduleID OUTPUT  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_attach_schedule  >> secondaryadd.sql
echo		@job_id = @LS_Secondary__CopyJobId  >> secondaryadd.sql
echo		,@schedule_id = @LS_SecondaryCopyJobScheduleID   >> secondaryadd.sql

echo DECLARE @LS_SecondaryRestoreJobScheduleUID	As uniqueidentifier  >> secondaryadd.sql
echo DECLARE @LS_SecondaryRestoreJobScheduleID	AS int  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_add_schedule  >> secondaryadd.sql
echo		@schedule_name =N'DefaultRestoreJobSchedule'  >> secondaryadd.sql
echo		,@enabled = 1  >> secondaryadd.sql
echo		,@freq_type = 4  >> secondaryadd.sql
echo		,@freq_interval = 1  >> secondaryadd.sql
echo		,@freq_subday_type = 4  >> secondaryadd.sql
echo		,@freq_subday_interval = 15  >> secondaryadd.sql
echo		,@freq_recurrence_factor = 0  >> secondaryadd.sql
echo		,@active_start_date = 20160607  >> secondaryadd.sql
echo		,@active_end_date = 99991231  >> secondaryadd.sql
echo		,@active_start_time = 0  >> secondaryadd.sql
echo		,@active_end_time = 235900  >> secondaryadd.sql
echo		,@schedule_uid = @LS_SecondaryRestoreJobScheduleUID OUTPUT  >> secondaryadd.sql
echo		,@schedule_id = @LS_SecondaryRestoreJobScheduleID OUTPUT  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_attach_schedule  >> secondaryadd.sql
echo		@job_id = @LS_Secondary__RestoreJobId  >> secondaryadd.sql
echo		,@schedule_id = @LS_SecondaryRestoreJobScheduleID   >> secondaryadd.sql

echo END  >> secondaryadd.sql

echo DECLARE @LS_Add_RetCode2	As int  >> secondaryadd.sql

echo IF (@@ERROR = 0 AND @LS_Add_RetCode = 0)  >> secondaryadd.sql
echo BEGIN  >> secondaryadd.sql

echo EXEC @LS_Add_RetCode2 = master.dbo.sp_add_log_shipping_secondary_database  >> secondaryadd.sql
echo		@secondary_database = N'!db!'  >> secondaryadd.sql
echo		,@primary_server = N'!primary!'  >> secondaryadd.sql
echo		,@primary_database = N'!db!'  >> secondaryadd.sql
echo		,@restore_delay = 0  >> secondaryadd.sql
echo		,@restore_mode = 1  >> secondaryadd.sql
echo		,@disconnect_users	= 1  >> secondaryadd.sql
echo		,@restore_threshold = 45    >> secondaryadd.sql
echo		,@threshold_alert_enabled = 1  >> secondaryadd.sql
echo		,@history_retention_period	= 5760  >> secondaryadd.sql
echo		,@overwrite = 1  >> secondaryadd.sql
echo		,@ignoreremotemonitor = 1  >> secondaryadd.sql

echo END  >> secondaryadd.sql

echo IF (@@error = 0 AND @LS_Add_RetCode = 0)  >> secondaryadd.sql
echo BEGIN  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_update_job  >> secondaryadd.sql
echo		@job_id = @LS_Secondary__CopyJobId  >> secondaryadd.sql
echo		,@enabled = 1  >> secondaryadd.sql

echo EXEC msdb.dbo.sp_update_job  >> secondaryadd.sql
echo	 	@job_id = @LS_Secondary__RestoreJobId  >> secondaryadd.sql
echo		,@enabled = 1  >> secondaryadd.sql

echo END  >> secondaryadd.sql
GOTO :STARTLOGSHIP

:MONITORADD
echo EXEC msdb.dbo.sp_processlogshippingmonitorprimary  > primarymonitoradd.sql
echo		@mode = 1  >> primarymonitoradd.sql
echo		,@primary_id = N'!primary_id!'  >> primarymonitoradd.sql
echo		,@primary_server = N'!primary!'  >> primarymonitoradd.sql
echo		,@monitor_server = N'!monitor!'  >> primarymonitoradd.sql
echo		,@monitor_server_security_mode = 1  >> primarymonitoradd.sql
echo		,@primary_database = N'!db!'  >> primarymonitoradd.sql
echo		,@backup_threshold = 60  >> primarymonitoradd.sql
echo		,@threshold_alert = 14420  >> primarymonitoradd.sql
echo		,@threshold_alert_enabled = 1  >> primarymonitoradd.sql
echo		,@history_retention_period = 5760  >> primarymonitoradd.sql

echo EXEC msdb.dbo.sp_processlogshippingmonitorsecondary   > secondarymonitoradd.sql
echo		@mode = 1 >> secondarymonitoradd.sql
echo		,@secondary_server = N'!secondary!'  >> secondarymonitoradd.sql
echo		,@secondary_database = N'!db!'  >> secondarymonitoradd.sql
echo		,@secondary_id = N'!secondary_id!'  >> secondarymonitoradd.sql
echo		,@primary_server = N'!primary!'  >> secondarymonitoradd.sql
echo		,@primary_database = N'!db!'  >> secondarymonitoradd.sql
echo		,@restore_threshold = 45    >> secondarymonitoradd.sql
echo		,@threshold_alert = 14420  >> secondarymonitoradd.sql
echo		,@threshold_alert_enabled = 1  >> secondarymonitoradd.sql
echo		,@history_retention_period	= 5760  >> secondarymonitoradd.sql
echo		,@monitor_server = N'!monitor!'  >> secondarymonitoradd.sql
echo		,@monitor_server_security_mode = 1  >> secondarymonitoradd.sql

GOTO :MONITORSTART

:LOGGING
echo %date% - %time% : %1
echo.
rem add to log
echo %date% - %time% : %1 >> !logfile!
GOTO :EOF

:END
echo Exiting.