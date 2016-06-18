#!/bin/bash

# Version: 201606181214

# Code based on http://domwatson.codes/2010/12/cheaper-online-backup-and-sync-part-2.html

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
scripthome=/etc/P5Software/s3cmd
s3cmdlocation=/usr/local/bin
logfile=$scripthome/backup.log
servername=$(uname -n)
s3bucket=com.monorailyellow.lan.$servername
excludefile=$scripthome/s3cmd.exclude
includefile=$scripthome/s3cmd.include
confirmationemail=brent.hendricks@monorailyellow.com
isDatabaseServer=true
DatabaseBackupScript="/etc/P5Software/mongodb/mongodbBackup.sh"
dryrun=true

# ------------------------------------------------------------
# Begin Script Execution
# ------------------------------------------------------------

#Remove the existing log file
rm $logfile

echo "Sarting backup `date`..." >> $logfile

# ------------------------------------------------------------
# Am I Running already? (code thanks to http://www.franzone.com/2007/09/23/how-can-i-tell-if-my-bash-script-is-already-running/comment-page-1/)
# ------------------------------------------------------------
if [ ! -z "`ps -C \`basename $0\` --no-headers -o "pid,ppid,sid,comm"|grep -v "$$ "|grep -v "<defunct>"`" ]; then

	#script is already running – abort
	echo ==> !!!!! ====> =ERROR! <==== !!!!! <== >> $logfile
	echo `date`... Script is already running, aborting. >> $logfile

	#Send a failure message
	cat $logfile | mail -s $servername" Backup FAILED" $confirmationemail

	exit 1
fi

# ------------------------------------------------------------
# RUN THE BACKUP COMMANDS
# ------------------------------------------------------------

# Back up the files
echo ==================================== >> $logfile

# See if we are a database server.  If so, we need to run the database backup script first
if [ "$isDatabaseServer" = "true" ]; then

	echo "This is a database server.  Backing up the databases..." >> $logfile
	echo "Command being executed: ["$DatabaseBackupScript"]" >> $logfile
	$DatabaseBackupScript >> $logfile 2>&1

echo "Done backing up database." >> $logfile

echo ==================================== >> $logfile
fi

executescript=$s3cmdlocation"/s3cmd sync / --verbose --delete-removed --reduced-redundancy --include-from=$includefile --exclude-from=$excludefile " 

#see if this is a dry run
if [ "$dryrun" = "true" ]; then
     executescript+=" --dry-run "
     echo "Dry-run enabled!  This is the initial default setting." >> $logfile
fi

executescript+="s3://${s3bucket,,}/"

echo "Command being executed is: [ "$executescript" ]" >> $logfile

#Run the command that was built
$executescript >> $logfile

echo ==================================== >> $logfile

echo Process completed `date`. >> $logfile

#Upload the log file
executescript=$s3cmdlocation"/s3cmd put $logfile --reduced-redundancy s3://${s3bucket,,}$logfile" 

echo "Command being executed is: [ "$executescript" ]"

#execute the upload
$executescript

# ------------------------------------------------------------
#Send today's log file in an email
# ------------------------------------------------------------

if [ "$dryrun" = "true" ]; then
	cat $logfile | mail -s $servername" !!! DRY RUN!!! Backup Executed" $confirmationemail
else
	cat $logfile | mail -s $servername" Backup Executed" $confirmationemail
fi

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
exit 0

