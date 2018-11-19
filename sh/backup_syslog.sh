#!/bin/bash

PROGNAME=$(basename $0)
filedate=$(date '+%Y%m%d')



error_exit()
{
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        #send to syslog
        /usr/bin/logger "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        #create a ticket with the error
        mail -s "Syslog Backup Error!" support@company.com <<< "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

#cp local backup
cmd=$(gzip -9c /var/log/syslog.1 > /root/syslog_backup/syslog_backup-$filedate.gz 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(gzip -9c /var/log/auth.log.1 > /root/syslog_backup/authlog_backup-$filedate.gz 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#copy to rxfp01 for archive
#you have to mount the share before you can write to it rather than just copying directly to it /rolleyes
cmd=$(mount -t cifs -o username=user,password=Password1,domain=domain //server/UserData$/ /root/tmp/mnt 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#copy the files over
cmd=$(cp /root/syslog_backup/syslog_backup-$filedate.gz /root/tmp/mnt/user/syslog_backup/ 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(cp /root/syslog_backup/authlog_backup-$filedate.gz /root/tmp/mnt/user/syslog_backup/ 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#unmount the share
cmd=$(umount /root/tmp/mnt 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#delete any backups older than 30 days
cmd=$(cd /root/syslog_backup 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(find . -mindepth 1 -mtime +30 -delete 2>&1) || error_exit "Error on line number $LINENO: $cmd!"


#log to syslog
/usr/bin/logger "Syslog backup complete!"

#load logs to rxdevsql01
#copy to tmp dir
#cmd=$(cp /var/log/syslog.1 /root/tmp/ 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#cmd=$(cp /var/log/auth.log.1 /root/tmp/ 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#load the logs into mssql
#cmd=$(/usr/bin/python /root/scripts/load_logs_mssql.py /root/tmp/syslog.1 syslogs 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#cmd=$(/usr/bin/python /root/scripts/load_logs_mssql.py /root/tmp/auth.log.1 authlogs 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#delete the temp files
#cmd=$(rm /root/tmp/*.1 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#log to syslog
#/usr/bin/logger "Syslog load to sqlserver complete!"

#Notify if successful
#mail -s "Syslog backup complete!" user@company.com <<< "Syslog backup complete!"
