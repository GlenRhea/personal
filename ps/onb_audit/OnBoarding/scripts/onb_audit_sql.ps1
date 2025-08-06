#Requires -Modules SqlServer
#Requires -RunAsAdministrator

. .\onb_audit_functions.ps1

$outputPath = "$outputPath\modules\sql"
if (!(Test-Path $outputPath)) {
    $null = New-Item -ItemType directory -Force -Path $outputPath
}
Output-Log warn "Starting the SQL script!"
Output-Log info "SQL - All reports will be here: $outputPath"

Try {
    #get the server name/instance first     
    $instances = Get-ChildItem -Path SQLSERVER:\SQL\localhost
    $instances = $instances.InstanceName
    $hostname = $env:COMPUTERNAME
    foreach ($instance in $instances) {
        $serverInstance = "$hostname\$instance"
        #this assumes connectivity for the current user
        #get server versions and licensing model
        $version = Invoke-Sqlcmd -Query "SELECT @@version" -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $version | Export-Csv -Path "$outputPath\$serverInstance-sql_version1.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting versions"

        $query = "SELECT SERVERPROPERTY('productversion') as ProductVersion, SERVERPROPERTY ('productlevel') as ProductLevel, SERVERPROPERTY ('edition'), SERVERPROPERTY('LicenseType') AS LicenseType;"
        $version = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $version | Export-Csv -Path "$outputPath\sql_version2.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting versions2"

        #get db sizes and locations
        $query = "SELECT 
            mdf.database_id, 
            mdf.name, 
            mdf.physical_name as data_file, 
            ldf.physical_name as log_file, 
            db_size = CAST((mdf.size * 8.0)/1024 AS DECIMAL(8,2)), 
            log_size = CAST((ldf.size * 8.0 / 1024) AS DECIMAL(8,2))
            FROM (SELECT * FROM sys.master_files WHERE type_desc = 'ROWS' ) mdf
            JOIN (SELECT * FROM sys.master_files WHERE type_desc = 'LOG' ) ldf
            ON mdf.database_id = ldf.database_id"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_dbs.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting DB sizes and locations"

        #get all login accounts
        $query = "select * from sys.syslogins"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_all_logins.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting all logins"

        #get all currently logged in users
        $query = "EXEC sp_who"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_current_users.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting currently logged in users"

        #check for uncommitted transactions
        $query = "SELECT 
            er.session_id
            ,er.open_transaction_count
            FROM sys.dm_exec_requests er
            where er.open_transaction_count > 0
            ORDER BY open_resultset_count desc"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_uncommited_transactions.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting uncommitted transactions"

        #check for expensive queries
        $query = "SELECT   SPID       = er.session_id
            ,STATUS         = ses.STATUS
            ,[Login]        = ses.login_name
            ,Host           = ses.host_name
            ,BlkBy          = er.blocking_session_id
            ,DBName         = DB_Name(er.database_id)
            ,CommandType    = er.command
            ,ObjectName     = OBJECT_NAME(st.objectid)
            ,CPUTime        = er.cpu_time
            ,StartTime      = er.start_time
            ,TimeElapsed    = CAST(GETDATE() - er.start_time AS TIME)
            ,SQLStatement   = st.text
        FROM    sys.dm_exec_requests er
            OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
            LEFT JOIN sys.dm_exec_sessions ses
            ON ses.session_id = er.session_id
        LEFT JOIN sys.dm_exec_connections con
            ON con.session_id = ses.session_id
        WHERE   st.text IS NOT NULL"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_expensive_queries.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting expensive queries"

        #check for blocking sessions
        $query = "SELECT session_id, start_time, command, status, blocking_session_id, wait_time FROM sys.dm_exec_requests WHERE blocking_session_id <> 0; "
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_blocking_sessions.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting blocking sessions"

        #check for locks and waits
        $query = "Select TableName = OBJECT_SCHEMA_NAME(TL.resource_associated_entity_id) + N'.' + object_name(TL.resource_associated_entity_id), 
                LockMode = TL.request_mode,
                LockStatus = TL.request_status,
                Command = R.command,
                QueryStatus = R.status,
                CurrentWait = R.wait_type,
                LastWait = R.last_wait_type,
                WaitResource = R.wait_resource,
                SQLText = SUBSTRING(ST.text, (R.statement_start_offset/2)+1, 
                    ((Case R.statement_end_offset
                        When -1 Then DATALENGTH(ST.text)
                        Else R.statement_end_offset
                    End - R.statement_start_offset)/2) + 1),
                QueryPlan = Q.query_plan
            From sys.dm_tran_locks TL
            Inner Join sys.dm_exec_requests R On R.session_id = TL.request_session_id
            Outer Apply sys.dm_exec_sql_text(R.sql_handle) As ST
            Outer Apply sys.dm_exec_query_plan(R.plan_handle) As Q
            Where TL.resource_type = 'OBJECT'
            --And TL.resource_associated_entity_id = OBJECT_ID('<Table Name>')
            And TL.resource_database_id = DB_ID();"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_locks.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting db locks"

        #check for fragmented indexes
        $query = "SELECT dbschemas.[name] as 'Schema', 
            dbtables.[name] as 'Table', 
            dbindexes.[name] as 'Index',
            indexstats.alloc_unit_type_desc,
            ROUND(indexstats.avg_fragmentation_in_percent, 2),
            indexstats.page_count
            FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
            INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
            INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
            INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
            AND indexstats.index_id = dbindexes.index_id
            WHERE indexstats.database_id = DB_ID() AND dbindexes.[name] IS NOT NULL
                AND indexstats.page_count > 1000
            --ORDER BY indexstats.avg_fragmentation_in_percent desc
            ORDER BY indexstats.page_count desc"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_fragmented_indexes.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting fragmented indexes"

        #check for maintenance tasks
        $query = "select 
            p.name as 'Maintenance Plan'
            ,p.[description] as 'Description'
            ,p.[owner] as 'Plan Owner'
            ,sp.subplan_name as 'Subplan Name'
            ,sp.subplan_description as 'Subplan Description'
            ,j.name as 'Job Name'
            ,j.[description] as 'Job Description'  
        from msdb..sysmaintplan_plans p
            inner join msdb..sysmaintplan_subplans sp
            on p.id = sp.plan_id
            inner join msdb..sysjobs j
            on sp.job_id = j.job_id
        where j.[enabled] = 1"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_tasks.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting all maintenance plans"

        #check for missing backups
        $query = "SELECT CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
            master.sys.sysdatabases.NAME AS database_name,  
            NULL AS [Last Data Backup Date],  
            9999 AS [Backup Age (Hours)]  
        FROM master.sys.sysdatabases 
            LEFT JOIN msdb.dbo.backupset ON master.sys.sysdatabases.name = msdb.dbo.backupset.database_name 
        WHERE msdb.dbo.backupset.database_name IS NULL 
            AND master.sys.sysdatabases.name <> 'tempdb' 
        ORDER BY msdb.dbo.backupset.database_name"
        $output = Invoke-Sqlcmd -Query $query -ServerInstance $serverInstance -TrustServerCertificate -OutputSqlErrors $true
        $output | Export-Csv -Path "$outputPath\$serverInstance-sql_missed_backups.csv" -NoTypeInformation -Encoding UTF8 -Force
        Output-Log info "SQL - Outputting missing backups"
    }
    
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
