#!/bin/bash
# This script runs the automated test to proof that the chaos-monkey runns correctly
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

BACKUP_DIR="/data/chaos-monkey/backup"

IP_ADDRESS=$(hostname -I | awk '{print $1}')
K8S_HOST_LIST=($(kubectl get nodes |grep -v "NAME" |awk '{print $1}'))
K8S_HOST_LIST_LENGTH=${#K8S_HOST_LIST[@]}

#----------------------------------------------------------------------------------------------
# A001 - Chaos-Monkey Host prüfen
#----------------------------------------------------------------------------------------------
# ping auf ip von server
status_A001="NOK"

ping -c1 -W1 $IP_ADDRESS && status_A001="OK" || status_A001="NOK"


#----------------------------------------------------------------------------------------------
# A002 - Chaos-Monkey aufrufen
#----------------------------------------------------------------------------------------------
status_A002="NOK"

if [ -s /data/chaos-monkey/chaosmonkey.log ]; then
        # The log file is not empty
        status_A002="OK"
else
        # The log file is empty.
        status_A002="NOK - log file is empty!"
fi

#----------------------------------------------------------------------------------------------
# A003 - Root SSH Login
#----------------------------------------------------------------------------------------------
status_A003="NOK"

ssh root@$IP_ADDRESS -qo PasswordAuthentication=no status_A003="NOK" || status_A003="OK"

#----------------------------------------------------------------------------------------------
# A004 - Kubernetes Cluster aufrufen
#----------------------------------------------------------------------------------------------
status_A004="NOK"

if [[ $K8S_HOST_LIST_LENGTH -gt 2 ]];
then
    status_A004="OK"
fi

#----------------------------------------------------------------------------------------------
# A005 - Demo-Applikationen laufen
#----------------------------------------------------------------------------------------------
status_A005="NOK"

PODS_SOCKSHOP=($(kubectl get pods --namespace sockshop |grep -v "NAME" |awk '{print $1}'))
PODS_SOCKSHOP_LENGTH=${#PODS_SOCKSHOP[@]}

PODS_ONLINEBOUTIQUE=($(kubectl get pods --namespace onlineboutique |grep -v "NAME" |awk '{print $1}'))
PODS_ONLINEBOUTIQUE_LENGTH=${#PODS_ONLINEBOUTIQUE[@]}

PODS_YELB=($(kubectl get pods --namespace yelb |grep -v "NAME" |awk '{print $1}'))
PODS_YELB_LENGTH=${#PODS_YELB[@]}

echo $PODS_SOCKSHOP_LENGTH
echo $PODS_ONLINEBOUTIQUE_LENGTH
echo $PODS_YELB_LENGTH

if [[ $PODS_SOCKSHOP_LENGTH -gt 4 ]];
then
    if [[ $PODS_ONLINEBOUTIQUE_LENGTH -gt 4 ]];
    then
        if [[ $PODS_YELB_LENGTH -gt 2 ]];
        then  
            status_A005="OK"
        fi
    fi
fi

#----------------------------------------------------------------------------------------------
# Create Test output
#----------------------------------------------------------------------------------------------
CURRENT_DATE=`date +%Y%m%d`

if [[ $status_A001 -eq "NOK" || $status_A002 -eq "NOK" || $status_A003 -eq "NOK" || $status_A004 -eq "NOK" || $status_A005 -eq "NOK" ]];
then
    {  
        echo "- - - - - - - - - - - - - -"
        echo "TEST OUTPUT $CURRENT_DATE"
        echo "- - - - - - - - - - - - - -"
        echo "A001: $status_A001"
        echo "A002: $status_A002"
        echo "A003: $status_A003"
        echo "A004: $status_A004"
        echo "A005: $status_A005"
    } >> $BACKUP_DIR/test_error.log
fi

{  
    echo "- - - - - - - - - - - - - -"
    echo "TEST OUTPUT"
    echo "- - - - - - - - - - - - - -"
    echo "A001: $status_A001"
    echo "A002: $status_A002"
    echo "A003: $status_A003"
    echo "A004: $status_A004"
    echo "A005: $status_A005"
} > $BACKUP_DIR/test_output.log