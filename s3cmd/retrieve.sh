#!/bin/bash

# Code based on http://domwatson.codes/2010/12/cheaper-online-backup-and-sync-part-2.html

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
P5SoftwareHome=/etc/P5Software/Linux-Tools
scripthome=$P5SoftwareHome/s3cmd
s3cmdlocation=/usr/local/bin
logfile=$scripthome/retrieval.log
excludefile=$scripthome/s3cmd.exclude
includefile=$scripthome/s3cmd.include

# Read the configuration file
source $scripthome/s3cmd.conf

# ------------------------------------------------------------
# Begin Script Execution
# ------------------------------------------------------------

#Remove the existing log file and start a new one
echo "Sarting retrieval `date`..." > $logfile

# ------------------------------------------------------------
# Am I Running already? (code thanks to http://www.franzone.com/2007/09/23/how-can-i-tell-if-my-bash-script-is-already-running/comment-page-1/)
# ------------------------------------------------------------
if [ ! -z "`ps -C \`basename $0\` --no-headers -o "pid,ppid,sid,comm"|grep -v "$$ "|grep -v "<defunct>"`" ]; then

	#script is already running – abort
	echo ==> !!!!! ====> =ERROR! <==== !!!!! <== >> $logfile
	echo `date`... Script is already running, aborting. >> $logfile

	#Send a failure message
	cat $logfile | mail -s $serverHostname" Retrieval FAILED" $emailAddress

	exit 1
fi

# ------------------------------------------------------------
# RUN THE BACKUP COMMANDS
# ------------------------------------------------------------

# Retrieve the files
echo ==================================== >> $logfile

executescript=$s3cmdlocation"/s3cmd get s3://${s3BucketName,,} --skip-existing --recursive --verbose --include-from=$includefile --exclude='_*' --exclude='$scripthome' --exclude-from=$excludefile /"

#see if this is a dry run
if [ "$isDryRun" = "true" ]; then
     executescript+=" --dry-run "
     echo "Dry-run enabled!" >> $logfile
fi

echo "Command being executed is: [ "$executescript" ]" >> $logfile

#Run the command that was built
$executescript >> $logfile

echo ==================================== >> $logfile

echo Process completed `date`. >> $logfile

#Upload the log file
executescript=$s3cmdlocation"/s3cmd put $logfile --reduced-redundancy s3://${s3BucketName,,}$logfile"

echo "Command being executed is: [ "$executescript" ]"

#execute the upload
$executescript

# ------------------------------------------------------------
#Send today's log file in an email
# ------------------------------------------------------------

if [ "$isDryRun" = "true" ]; then
	cat $logfile | mail -s $serverHostname" !!! DRY RUN!!! Retrieval Executed" $emailAddress
else
	cat $logfile | mail -s $serverHostname" Retrieval Executed" $emailAddress
fi

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
exit 0

