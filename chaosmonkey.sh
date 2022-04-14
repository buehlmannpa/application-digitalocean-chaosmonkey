#!/bin/bash
# This script kill pods on a kubernetes cluster at a certain time period. This is the main
# component named "Chaos-Monkey".
#
# Copyright 2022 Patrick Bühlmann
#
#----------------------------------------------------------------------------------------------
# IMPLEMENTATION
#   version         1.0.0
#   author          Patrick Bühlmann
#   copyright       Copyright (c) www.patrick21.ch
#   license         GNU General Public License
#
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------
# CHAOS-MONKEY
#----------------------------------------------------------------------------------------------
echo -e "\033[1;36m  Let's start to make some chaos \033[0;35m"
cat << "EOF"
              __,__
     .--.  .-"     "-.  .--.
    / .. \/  .-. .-.  \/ .. \
   | |  '|  /   Y   \  |'  | |
   | \   \  \ 0 | 0 /  /   / |
    \ '- ,\.-"`` ``"-./, -' /
     `'-' /_   ^ ^   _\ '-'`
         |  \._   _./  |
         \   \ `~` /   /
          '._ '-=-' _.'
             '~---~' 
EOF

echo -e "\033[0m"

#----------------------------------------------------------------------------------------------
# var declaration
#----------------------------------------------------------------------------------------------
LOG_DIR="/data/chaos-monkey"
DOWNLOAD_DIR="/home/chaosmonkey/download"
HOME_DIR="/home/chaosmonkey/chaosmonkey-app"

CONFIG_EXCLUDED_WEEKDAYS=`cat $HOME_DIR/config | grep excluded-weekdays | sed 's/.*=//'`
CONFIG_EXCLUDED_NAMESPACES=`cat $HOME_DIR/config | grep excluded-namespaces | sed 's/.*=//'`
CONFIG_EXCLUDE_NEW_PODS=`cat $HOME_DIR/config | grep exclude-new-pods | sed 's/.*=//'`
CONFIG_DELETE_PERIOD=`cat $HOME_DIR/config | grep delete-period | sed 's/.*=//'`
CONFIG_BACKUP_TIME=`cat $HOME_DIR/config | grep backup-time | sed 's/.*=//'`

DAY_OF_WEEK=`date | awk '{print $1}'`

CRONJOB_NAME="chaosmonkey_cronjobs"

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
BACKGROUND_RED='\033[0;41m'


# Connect doctl with the DigitalOcean account
$DOWNLOAD_DIR/doctl auth init -t $(cat $HOME_DIR/do_token)

# Call "get_kubeconfig" script to get the current kubeconfig of all DigitalOcean
# kubernetes cluster
source $HOME_DIR/get_kubeconfig.sh

echo "- - - - - - - - - - - - - - - -"


# var needs to be declared after doctl and kubectl config
ALL_KUBERNETES_NAMESPACES=($(kubectl get namespaces | grep -v NAME | awk '{print $1}'))


#----------------------------------------------------------------------------------------------
# FUNCTION: invalid_input_error
# This function returns a structured error with the output from the input args
#----------------------------------------------------------------------------------------------
function invalid_input_error() {
    echo -e "${BACKGROUND_RED}ERROR${NOCOLOR}: no valid input... " ${RED} "'"$1"'" ${NOCOLOR}
}

#----------------------------------------------------------------------------------------------
# FUNCTION: info_output
# This function returns info message with the output from the input args
#----------------------------------------------------------------------------------------------
function info_output() {
    echo -e "${LIGHTGREEN}INFO${NOCOLOR}:" $1
}

#----------------------------------------------------------------------------------------------
# FUNCTION: check_weekday_with_currentday
# This function checks if the the current day matches with the day from the 
#  config-file and display a message if matching or not.
#
# If the day is matching, the script will automatically exit!
#----------------------------------------------------------------------------------------------
function check_weekday_with_currentday() {
    case $DAY_OF_WEEK in

        $1)
            #Options: Mo,Tue,Wed,Thr,Fri,Sat,Sun
            info_output "Nothing to do! Today is an excluded day ("$1")"
            exit
            ;;

        *)
            info_output "Day can be ignored ("$1")"
            ;;
    esac
}

#----------------------------------------------------------------------------------------------
# FUNCTION: activate_cronjob
# This function activates the cronjob to run this script automatically and eliminate pods
#----------------------------------------------------------------------------------------------
function activate_cronjob() {
    crontab $DOWNLOAD_DIR/$CRONJOB_NAME
    rm $DOWNLOAD_DIR/$CRONJOB_NAME
}



#----------------------------------------------------------------------------------------------
# PART: check config parameter 'excluded-weekdays'
#----------------------------------------------------------------------------------------------
if [[ $CONFIG_EXCLUDED_WEEKDAYS == "none" ]];
then
    info_output "Days can be ignored"

elif [[ $CONFIG_EXCLUDED_WEEKDAYS != *","* ]];
then
    check_weekday_with_currentday $CONFIG_EXCLUDED_WEEKDAYS

elif [[ $CONFIG_EXCLUDED_WEEKDAYS == *","* ]];
then
    IFS=',' read -r -a LIST_OF_WEEKDAYS <<< "$CONFIG_EXCLUDED_WEEKDAYS"
    for day in "${LIST_OF_WEEKDAYS[@]}"
    do
        check_weekday_with_currentday $day
    done
else
    invalid_input_error $CONFIG_EXCLUDED_WEEKDAYS
fi


#----------------------------------------------------------------------------------------------
# PART: check config parameter 'excluded-namespaces'
#----------------------------------------------------------------------------------------------
IFS=',' read -r -a CONFIG_NAMESPACE_LIST <<< "$CONFIG_EXCLUDED_NAMESPACES"

if [[ $CONFIG_NAMESPACE_LIST == "none" ]];
then
    info_output "Namespace limitation can be ignored"
else
    for namespace in "${!ALL_KUBERNETES_NAMESPACES[@]}"
    do
        for config_namespaces in "${CONFIG_NAMESPACE_LIST[@]}"
        do
            if [[ $config_namespaces == ${ALL_KUBERNETES_NAMESPACES[$namespace]} ]];
            then
                unset ALL_KUBERNETES_NAMESPACES[$namespace]
            fi
        done
    done

    info_output "Target Namespaces: "
    echo "|_____"${ALL_KUBERNETES_NAMESPACES[@]}
fi

# renumbering the indices of ALL_KUBERNETES_NAMESPACES
ALL_KUBERNETES_NAMESPACES=("${ALL_KUBERNETES_NAMESPACES[@]}")


#----------------------------------------------------------------------------------------------
# PART: check config parameter 'exclude-new-pods' (new pod == lives less than 1h)
#----------------------------------------------------------------------------------------------
if [[ $CONFIG_EXCLUDE_NEW_PODS == "yes" ]];
then
    info_output "New created pods which are less than 1h old are not deleted"

elif [[ $CONFIG_EXCLUDE_NEW_PODS == "no" ]];
then
    info_output "All pods are recognized as targets"
else
    invalid_input_error $CONFIG_EXCLUDE_NEW_PODS
fi


#----------------------------------------------------------------------------------------------
# PART: check config parameter 'backup-time' and set time for cronjob
#----------------------------------------------------------------------------------------------
$BACKUP_HOUR=${CONFIG_BACKUP_TIME:0:2}
$BACKUP_MINUTE=${CONFIG_BACKUP_TIME:3:2}

if (( BACKUP_MINUTE >= 1 && BACKUP_MINUTE <= 23 && BACKUP_HOUR >= 1 && BACKUP_HOUR <= 23  ));
then
    info_output "backup-time is set to $CONFIG_BACKUP_TIME"
    BACKUP_TIME="$BACKUP_HOUR $BACKUP_MINUTE"
else
    invalid_input_error "backup-time: $CONFIG_BACKUP_TIME"
    exit
fi


#----------------------------------------------------------------------------------------------
# PART: check config parameter 'delete-period' and set cronjob to run script automatically
#----------------------------------------------------------------------------------------------
CONFIG_PERIOD_NUMBER=${CONFIG_DELETE_PERIOD%?}
CONFIG_PERIOD_UNIT=${CONFIG_DELETE_PERIOD: -1}


if [[ $CONFIG_PERIOD_NUMBER -gt 100 ]];
then
    invalid_input_error $CONFIG_PERIOD_NUMBER
fi

case $CONFIG_PERIOD_UNIT in
    #Options: m=minutes,h=hours,d=days
    # * * * * * "command to be executed"
    # | | |
    # | | --------- Day of month (1 - 31)
    # | ----------- Hour (0 - 23)
    # ------------- Minute (0 - 59)
    "m")
        if [[ $CONFIG_PERIOD_NUMBER -lt 60 ]];
        then
            info_output "Pods where automatically killed every "$CONFIG_PERIOD_NUMBER$CONFIG_PERIOD_UNIT
            echo "*/${CONFIG_PERIOD_NUMBER} * * * * $HOME_DIR/chaosmonkey.sh" > $DOWNLOAD_DIR/$CRONJOB_NAME
            echo "$BACKUP_TIME $HOME_DIR/backup.sh" >> $DOWNLOAD_DIR/$CRONJOB_NAME
            activate_cronjob
        fi
        ;;

    "h")
        if [[ $CONFIG_PERIOD_NUMBER -lt 24 ]];
        then
            info_output "Pods where automatically killed every "$CONFIG_PERIOD_NUMBER$CONFIG_PERIOD_UNIT
            echo "* */${CONFIG_PERIOD_NUMBER} * * * $HOME_DIR/chaosmonkey.sh" > $DOWNLOAD_DIR/$CRONJOB_NAME
            echo "$BACKUP_TIME $HOME_DIR/backup.sh" >> $DOWNLOAD_DIR/$CRONJOB_NAME
            activate_cronjob
        fi
        ;;

    "d")
        if [[ $CONFIG_PERIOD_NUMBER -lt 32 ]]
        then
            info_output "Pods where automatically killed every "$CONFIG_PERIOD_NUMBER$CONFIG_PERIOD_UNIT 
            echo "* * */${CONFIG_PERIOD_NUMBER} * * $HOME_DIR/chaosmonkey.sh" > $DOWNLOAD_DIR/$CRONJOB_NAME
            echo "$BACKUP_TIME $HOME_DIR/backup.sh" >> $DOWNLOAD_DIR/$CRONJOB_NAME
            activate_cronjob
        fi
        ;;

    *)
        invalid_input_error $CONFIG_PERIOD_UNIT
        exit
        ;;
esac


#----------------------------------------------------------------------------------------------
# PART: Eliminate Pods
#----------------------------------------------------------------------------------------------
LENGTH_NAMESPACES_LIST=${#ALL_KUBERNETES_NAMESPACES[@]}

# random starting at zero - if real numbers are wished paste +1
RANDOM_NUMBER_NAMESPACE=$(( ( RANDOM % $LENGTH_NAMESPACES_LIST ) ))

# target namespace to kill a pod
TARGET_NAMESPACE=${ALL_KUBERNETES_NAMESPACES[$RANDOM_NUMBER_NAMESPACE]}
info_output "Chosen Namespace to eliminate a pod: "$TARGET_NAMESPACE

# target pod list with all pods from the $TARGET_NAMESPACE
TARGET_PODS=($(kubectl get pods --namespace $TARGET_NAMESPACE | grep -v NAME | awk '{print $1}'))
LENGTH_TARGET_PODS=${#TARGET_PODS[@]}
RANDOM_NUMBER_POD=$(( ( RANDOM % $LENGTH_TARGET_PODS ) ))
TARGET_POD=${TARGET_PODS[$RANDOM_NUMBER_POD]}
info_output "Chosen Pod to eliminate: "$TARGET_POD

# get age of target pod and kill if it is old
POD_LIVETIME=$(kubectl get pod --namespace $TARGET_NAMESPACE $TARGET_POD |grep -v "NAME" |awk '{print $5}')
POD_LIVETIME_UNIT=${POD_LIVETIME: -1}

if [[ POD_LIVETIME_UNIT == "m" ]];
then
    exit
else
    ## KILL POD
    kubectl delete pod --namespace $TARGET_NAMESPACE $TARGET_POD 

    # Paste output from eliminated pod to logfile
    CURRENT_DATE=`date +%Y%m%d`
    CURRENT_TIME=`date +%H%M`
    echo -e "[$ORANGE$CURRENT_DATE-$CURRENT_TIME$NOCOLOR]$LIGHTBLUE Namespace$NOCOLOR: $TARGET_NAMESPACE -$LIGHTBLUE Pod$NOCOLOR: $TARGET_POD" >> $LOG_DIR/chaosmonkey-log-color.txt
    echo -e "[$CURRENT_DATE-$CURRENT_TIME] Namespace: $TARGET_NAMESPACE - Pod: $TARGET_POD" >> $LOG_DIR/chaosmonkey-log.txt
fi