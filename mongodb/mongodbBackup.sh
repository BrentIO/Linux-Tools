#!/bin/bash

# Version: 201606181214

#Script file loosely based on https://sheharyar.me/blog/regular-mongo-backups-using-cron/

BACKUP_TTL_DAYS=3
TIMESTAMP=`date +%F-%H%M`
MONGODUMP_PATH="/usr/bin/mongodump"
BACKUPS_DIR="/etc/P5Software/Linux-Tools/mongodb/backups"
BACKUP_NAME="$TIMESTAMP"
LOG_FILE="$BACKUPS_DIR/$BACKUP_NAME.log"

mkdir -p $BACKUPS_DIR

echo "Sarting database backup `date`..." >> $LOG_FILE

echo "Log file: " $LOG_FILE >> $LOG_FILE
echo "Backup Directory: "  $BACKUPS_DIR >> $LOG_FILE
echo "Backup Name: " $BACKUP_NAME >> $LOG_FILE

echo "" >> $LOG_FILE
echo "Dumping all collection data from database..." >> $LOG_FILE
echo "===========================" >> $LOG_FILE
echo "Command being executed is: [" $MONGODUMP_PATH  "]"
$MONGODUMP_PATH -vv >> $LOG_FILE 2>&1
echo "===========================" >> $LOG_FILE
echo "Done dumping data from MongoDB" >> $LOG_FILE

echo "" >> $LOG_FILE

mv dump $BACKUP_NAME >> $LOG_FILE

echo "Compressing Data" >> $LOG_FILE
echo "===========================" >> $LOG_FILE
tar -zcvf $BACKUPS_DIR/$BACKUP_NAME.tgz $BACKUP_NAME >> $LOG_FILE 2>&1
rm -rf $BACKUP_NAME >> $LOG_FILE 2>&1
echo "===========================" >> $LOG_FILE

echo "" >> $LOG_FILE

echo "Deleting files more than $BACKUP_TTL_DAYS old" >> $LOG_FILE
find $BACKUPS_DIR/* -mtime +$BACKUP_TTL_DAYS -exec rm {} \; >> $LOG_FILE 2>&1

echo "" >> $LOG_FILE
echo "Complete at `date`." >> $LOG_FILE
