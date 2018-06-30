#!/bin/bash

# Version: 20180630

#Script file loosely based on https://sheharyar.me/blog/regular-mongo-backups-using-cron/

#Colors!
GREEN='\033[1;32m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
NC='\033[0m' # No Color

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
P5SoftwareHome=/etc/P5Software/Linux-Tools
scripthome=$P5SoftwareHome/influxdb
tmpDirectory=$scripthome/tmp
logfile=$scripthome/backup.log
influxdApplication=/usr/bin/influxd
influxDataDirectory=/var/lib/influxdb/data
timestamp=$(date +%F-%H%M)
backupTimeToLiveDays=3


#======== ERROR HANDLER ===========
ThrowError(){

	leftSideOutput=""
	rightSideOutput=""

	messageOutput="${RED}[`date +%Y-%m-%d` `date +%T.%3N`] Step Failed with Response Code $1.${NC}"

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

	exit $1

}

#======== EVENT LOGGER ===========
LogMessage(){

	lineOutput=""
    logDateTime=$(date +%Y-%m-%d)$(date +%T.%3N)
    messageOutput="${GREEN}$logDateTime ${NC}$1"

    #Get the message length but strip off any of the color characters
    messageLength=$(echo -e $messageOutput | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | wc -c)

	#Make the lines be as long as the message is, inclusive of timestamp.
	n=1;
	while [[ $n -lt $messageLength ]];
	do
	    lineOutput=$lineOutput"="
	    n=$((n+1));
	done

	#Do the output
    echo -e "\n${YELLOW}$lineOutput${NC}" |& tee -a $logfile
	echo -e "$messageOutput" |& tee -a $logfile
    echo -e "${YELLOW}$lineOutput${NC}\n" |& tee -a $logfile
}

#Set the pipefail so that we can catch errors on piped events
set -o pipefail

#Delete the temp directory if it exists
if [ -d $tmpDirectory ]
then
    rm -rf $tmpDirectory
fi

mkdir -p $tmpDirectory

#Remove the existing log file and create an empty
touch $logfile

LogMessage "Starting InfluxDB Backup Process"

LogMessage "Getting InfluxDB Server Version"
$influxdApplication version >> $tmpDirectory/version |& tee -a $logfile

#Check for errors	
responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\nError getting InfluxDB Server Version" |& tee -a $logfile
    ThrowError $responseCode
fi

#Output the data written to the file
echo -e "${CYAN}InfluxDB Server Version Information:${NC}" && cat $tmpDirectory/version

LogMessage "Getting InfluxDB Server Configuration"
$influxdApplication config >> $tmpDirectory/config |& tee -a $logfile

#Check for errors	
responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\n${RED}Error getting InfluxDB server configuration${NC}" |& tee -a $logfile
    ThrowError $responseCode
fi

#Output the data written to the file
echo -e "${CYAN}InfluxDB Server Configuration Information:${NC}" && cat $tmpDirectory/config


LogMessage "Getting InfluxDB Server Metadata"
$influxdApplication backup -host localhost:8088 $tmpDirectory |& tee -a $logfile

#Check for errors	
responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\n${RED}Error getting InfluxDB Server Metadata${NC}" |& tee -a $logfile
    ThrowError $responseCode
fi

#Cycle through each folder in the data directory, which represents a database.  This can be found in the config [data].dir parameter
for database in $(ls $influxDataDirectory -1)
do
    #Do not attempt to backup the _internal database
    if [ $database != "_internal" ]; then

        LogMessage "Backing up database ${PURPLE}$database"

        echo -e "${CYAN}Creating subfolder $tmpDirectory/$database...${NC}" |& tee -a $logfile
        mkdir -p $tmpDirectory/$database

        #Check for errors	
        responseCode=$?
        if [ $responseCode != 0 ]; then
            echo -e "\n${RED}Error creating subfolder $tmpDirectory/$database.${NC}" |& tee -a $logfile
            ThrowError $responseCode
        fi

        echo -e "\n${CYAN}Backing up database data files...${NC}" |& tee -a $logfile
        influxd backup -database $database -host localhost:8088 $tmpDirectory/$database |& tee -a $logfile

        #Check for errors	
        responseCode=$?
        if [ $responseCode != 0 ]; then
            echo -e "\n${RED}Error backing up database $database.${NC}" |& tee -a $logfile
            ThrowError $responseCode
        fi
    fi
done

LogMessage "Compressing Files"
tar -C $tmpDirectory/ -P -zcvf $scripthome/$timestamp.tgz . |& tee -a $logfile

#Check for errors	
responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\n${RED}Error compressing file." |& tee -a $logfile
    ThrowError $responseCode
fi

LogMessage "Deleting backups more than $backupTimeToLiveDays days old"

#find $scripthome/*.tgz -mtime +$backupTimeToLiveDays -exec rm {} \; |& tee -a $logfile

for filesToDelete in $(find $scripthome/*.tgz -mtime +$backupTimeToLiveDays)
do

    echo -e "${RED}Deleting:${NC} $filesToDelete" |& tee -a $logfile
    rm $filesToDelete

    responseCode=$?
    if [ $responseCode != 0 ]; then
        echo -e "\n${RED}Error deleting backup $filesToDelete" |& tee -a $logfile
        ThrowError $responseCode
    fi

done

LogMessage "Completed influxdb backup successfully"