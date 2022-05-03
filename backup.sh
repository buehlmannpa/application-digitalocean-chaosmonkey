#!/bin/bash
# This script creates a backup of the log from the "Chaos-Monkey" 
# Copyright 2022 Patrick Bühlmann
#
#----------------------------------------------------------------------------------------------
# IMPLEMENTATION
#   version         0.0.1
#   author          Patrick Bühlmann
#   copyright       Copyright (c) www.patrick21.ch
#   license         GNU General Public License
#
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------
# var declaration
#----------------------------------------------------------------------------------------------
LOG_DIR="/data/chaos-monkey"
BACKUP_DIR="/data/chaos-monkey/backup"
DOWNLOAD_DIR="/home/chaosmonkey/download"
CURRENT_DATE=`date +%Y%m%d`

CRONJOB_NAME="chaosmonkey_cronjobs"
BACKUP_TIME="23 23 * * *" #23:23
BACKUP_VOLUME_LOCATION="/mnt/vlscmn_fra1_vol1"


#----------------------------------------------------------------------------------------------
# Configure backup job (once at startup)
#----------------------------------------------------------------------------------------------
if [[ ! -f "$LOG_DIR/backup_ready" ]];
then
    touch $LOG_DIR/backup_ready
    # Create symbolic link for the webpage (exec once)
    ln -s /data/chaos-monkey/chaosmonkey.log /var/www/chaosmonkey/chaosmonkeylog
else
    echo "Backup is already initialized"


#----------------------------------------------------------------------------------------------
# Backup the current logfile (every day)
#----------------------------------------------------------------------------------------------
    #chaosmonkey-log-<date>.txt

    # copy the current logfile into the backup folder
    cp $LOG_DIR/chaosmonkey.log $BACKUP_DIR/chaosmonkey-log-$CURRENT_DATE.txt

    # copy the backup-logfile to the mounted volume
    sudo cp $BACKUP_DIR/chaosmonkey-log-$CURRENT_DATE.txt $BACKUP_VOLUME_LOCATION/chaosmonkey_backup/.

    # clear the current logfile(s)
    echo "" > $LOG_DIR/chaosmonkey.log
    echo "" > $LOG_DIR/chaosmonkey-color.log

fi