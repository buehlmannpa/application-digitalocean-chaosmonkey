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


#----------------------------------------------------------------------------------------------
# Configure backup job (once at startup)
#----------------------------------------------------------------------------------------------
if [[ ! -f "$LOG_DIR/backup_ready" ]];
then
    echo "$BACKUP_TIME $HOME_DIR/backup.sh" >> $DOWNLOAD_DIR/$CRONJOB_NAME
    crontab $DOWNLOAD_DIR/$CRONJOB_NAME

    touch $LOG_DIR/backup_ready
else
    echo "Backup is already initialized"


#----------------------------------------------------------------------------------------------
# Backup the current logfile (every day)
#----------------------------------------------------------------------------------------------
    #chaosmonkey-log-<date>.txt

    # copy the current logfile into the backup folder
    cp $LOG_DIR/chaosmonkey-log.txt $BACKUP_DIR/chaosmonkey-log-$CURRENT_DATE.txt

    # copy the backup-logfile to the backup host over scp (ssh connect doesn't work at the moment)
    ####### scp <datei> buehlmannpa@195.88.87.171:/home/buehlmannpa

    # clear the current logfile(s)
    echo "" > $LOG_DIR/chaosmonkey-log.txt
    echo "" > $LOG_DIR/chaosmonkey-log-color.txt

fi