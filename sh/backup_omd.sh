#!/bin/bash


PROGNAME=$(basename $0)
filedate=$(date '+%Y%m%d')



error_exit()
{
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        #send to syslog
        /usr/bin/logger "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        #create a ticket with the error
        mail -s "OMD Backup Error!" support@company.com <<< "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

#perform the backup
cmd=$(omd stop prod 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(omd backup prod /root/omd_backup/omd_prod_backup-$filedate.tgz 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(omd start prod 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#copy to rxfp01 for archive you have to mount the share before you can write to it rather than just copying directly to it /rolleyes
cmd=$(mount -t cifs -o username=user,password=Password1,domain=domain //server/UserData$/ /root/tmp/mnt 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
#copy the files over
cmd=$(cp /root/omd_backup/omd_prod_backup-$filedate.tgz /root/tmp/mnt/user/omd_backup/ 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#unmount the share
cmd=$(umount /root/tmp/mnt 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

#delete any backups older than 30 days
cmd=$(cd /root/omd_backup 2>&1) || error_exit "Error on line number $LINENO: $cmd!"
cmd=$(find . -mindepth 1 -mtime +30 -delete 2>&1) || error_exit "Error on line number $LINENO: $cmd!"

/usr/bin/logger "OMD backup complete!"

#Notify if successful
#mail -s "OMD backup complete!"  support@company.com <<< "OMD backup complete!"


