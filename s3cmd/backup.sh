#!/bin/bash

# Code based on http://domwatson.codes/2010/12/cheaper-online-backup-and-sync-part-2.html

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
P5SoftwareHome=/etc/P5Software/Linux-Tools
scripthome=$P5SoftwareHome/s3cmd
s3cmdlocation=/usr/local/bin
logfile=$scripthome/backup.log
DatabaseBackupScript=$P5SoftwareHome/mongodb/mongodbBackup.sh
excludefile=$scripthome/s3cmd.exclude
includefile=$scripthome/s3cmd.include

# Read the configuration file
source $scripthome/s3cmd.conf

PATH=/bin:/usr:/usr/bin:/usr/local/bin/:/etc/P5Software/Linux-Tools/s3cmd

#Set the pipefail so that we can catch errors on piped events
set -o pipefail

#Colors!
GREEN='\033[1;32m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#======== ERROR HANDLER ===========
ThrowError(){

	leftSideOutput=""
	rightSideOutput=""

	messageOutput="[`date +%Y-%m-%d` `date +%T.%3N`] Step Failed with Response Code $1."

	#Make the lines be as long as the message is, inclusive of timestamp and message.
	n=0;
	while [[ $n -lt $(((${#messageOutput})/2)) ]];
	do
	    leftSideOutput=$leftSideOutput">"
	    rightSideOutput=$rightSideOutput"<"
	n=$((n+1));
	done

	echo -e "\n\n$leftSideOutput ERROR $rightSideOutput" |& tee -a $logfile
	echo -e $messageOutput |& tee -a $logfile
	echo -e "$leftSideOutput ERROR $rightSideOutput\n\n" |& tee -a $logfile

	#Upload the log
	UploadLog
	
	#Send the email
	SendEmail "FAILED"

	exit $1

}

#======== Upload Log File ===========
UploadLog(){

	executescript="s3cmd put $logfile --reduced-redundancy s3://${s3BucketName,,}$logfile"

	#execute the upload
	$executescript
}


#======== Send Email ===========
SendEmail(){

	cat $logfile | mail -s "$serverHostname $1 Backup" $emailAddress

}


#======== EVENT LOGGER ===========
LogMessage(){

	lineOutput=""
	messageOutput="[`date +%Y-%m-%d` `date +%T.%3N`] $1"

	#Make the lines be as long as the message is, inclusive of timestamp.
	n=0;
	while [[ $n -lt ${#messageOutput} ]];
	do
	    lineOutput=$lineOutput"="
	    n=$((n+1));
	done

	#Do the output
	#echo -e "\n$lineOutput" |& tee -a $logfile
	echo -e "\n$messageOutput" |& tee -a $logfile
	#echo -e "$lineOutput\n" |& tee -a $logfile

}


#========  CREATE THE LOG ===========
rm $logfile
touch $logfile
LogMessage "Starting backup process for $serverHostname."


#========  OUTPUT SETTINGS TO THE CONSOLE ===========
echo -e "\n${BLUE}Current Settings:${NC}"
echo -e "\t${CYAN}P5SoftwareHome${NC}=${RED}$P5SoftwareHome${NC}"
echo -e "\t${CYAN}scripthome${NC}=${RED}$scripthome${NC}"
echo -e "\t${CYAN}s3cmdlocation${NC}=${RED}$s3cmdlocation${NC}"
echo -e "\t${CYAN}logfile${NC}=${RED}$logfile${NC}"
echo -e "\t${CYAN}DatabaseBackupScript${NC}=${RED}$DatabaseBackupScript${NC}"
echo -e "\t${CYAN}excludefile${NC}=${RED}$excludefile${NC}"
echo -e "\t${CYAN}includefile${NC}=${RED}$includefile${NC}"
echo -e "\t${CYAN}serverHostname${NC}=${RED}$serverHostname${NC}"
echo -e "\t${CYAN}serverFQDN${NC}=${RED}$serverFQDN${NC}"
echo -e "\t${CYAN}s3BucketName${NC}=${RED}$s3BucketName${NC}"
echo -e "\t${CYAN}emailAddress${NC}=${RED}$emailAddress${NC}"
echo -e "\t${CYAN}sendMailEvent${NC}=${RED}$sendMailEvent${NC}"
echo -e "\t${CYAN}isDatabaseServer${NC}=${RED}$isDatabaseServer${NC}"
echo -e "\t${CYAN}isDryRun${NC}=${RED}$isDryRun${NC}"
echo -e "\t${CYAN}alreadyExists${NC}=${RED}$alreadyExists${NC}"

#========  DELETE APPLE-SPECIFIC JUNK FILES ===========
LogMessage "Starting to delete junk files."
find / -iname "._*" -delete |& tee -a $logfile
find / -iname ".DS_Store" -delete |& tee -a $logfile
LogMessage "Completed deleting junk files."


# ------------------------------------------------------------
# Am I Running already? (code thanks to http://www.franzone.com/2007/09/23/how-can-i-tell-if-my-bash-script-is-already-running/comment-page-1/)
# ------------------------------------------------------------
if [ ! -z "`ps -C \`basename $0\` --no-headers -o "pid,ppid,sid,comm"|grep -v "$$ "|grep -v "<defunct>"`" ]; then

	#script is already running – abort
	echo -e "${RED}Script is already running, aborting.${NC}"
	ThrowError 99
fi

# ------------------------------------------------------------
# RUN THE BACKUP COMMANDS
# ------------------------------------------------------------

# Back up the files

# See if we are a database server.  If so, we need to run the database backup script first
if [ "$isDatabaseServer" = "true" ]; then
	
	LogMessage "This is a database server.  Backing up the databases."
	$DatabaseBackupScript |& tee -a $logfile
	
	#Check for errors	
	responseCode=$?
	if [ $responseCode != 0 ]; then
		echo -e "\nError backing up the database." |& tee -a $logfile
		ThrowError $responseCode
	fi	

	LogMessage "Database backup completed successfully."
else
	echo -e "\n${BLUE}This server is not configured to backup databases.${NC}"

fi

executescript="s3cmd sync / --stats --delete-removed --reduced-redundancy --follow-symlinks --verbose --include-from=$includefile --exclude-from=$excludefile "

#see if this is a dry run
if [ "$isDryRun" = "true" ]; then
     executescript+=" --dry-run "
	LogMessage "Dry-run enabled!  This is the initial default setting."
fi

executescript+="s3://${s3BucketName,,}/"

LogMessage "Starting s3cmd backup."

echo -e "\n${BLUE}Command being executed is [${CYAN} $executescript ${BLUE}]${NC}"

echo -e "\n${BLUE}No output will be shown until the process has completed.${NC}" 

#Run the command that was built, omitting "WARNING" messages
$executescript |& grep --invert-match "WARNING: Skipping over" >> $logfile

#Check for errors
responseCode=$?
if [ $responseCode != 0 ]; then
	echo -e "\nError occurred while executing s3cmd." |& tee -a $logfile
	ThrowError $responseCode
fi

LogMessage "Completed s3cmd backup successfully."

LogMessage "Completed backup process for $serverHostname."

echo -e ""

#Upload the log file
UploadLog

#Send the email
if [ "$isDryRun" = "true" ]; then
	SendEmail "DRY-RUN"
else
	#See if we should send an email
	if [ "$sendMailEvent" = "ONLY_ON_FAILURE" ]; then
		echo -e "\n${BLUE}No e-mail confirmation was requested in the configuration.${NC}"
	else
		SendEmail "Successful"
	fi
fi

exit 0