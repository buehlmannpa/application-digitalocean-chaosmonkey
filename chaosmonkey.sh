#!/bin/bash
# This script kill pods on a kubernetes cluster at a certain time period. This is the main
# component named "Chaos-Monkey".
#
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



# Connect doctl with the DigitalOcean account
#doctl auth init -t $(cat /home/chaosmonkey/do_token)

# Call "get_kubeconfig" script to get the current kubeconfig of all DigitalOcean
# kubernetes cluster
######################source get_kubeconfig.sh

echo "- - - - - - - - - - - - - - - -"

# Chaos-Monkey Logic
# check config file (once at startup!)

# var declaration
CONFIG_EXCLUDED_WEEKDAYS=`cat config | grep excluded-weekdays | sed 's/.*=//'`
CONFIG_EXCLUDED_NAMESPACES=`cat config | grep excluded-namespaces | sed 's/.*=//'`
CONFIG_EXCLUDE_NEW_PODS=`cat config | grep exclude-new-pods | sed 's/.*=//'`
CONFIG_DELETE_PERIOD=`cat config | grep delete-period | sed 's/.*=//'`

DAY_OF_WEEK=`date | awk '{print $1}'`

ALL_KUBERNETES_NAMESPACES=($(kubectl get namespaces | grep -v NAME | awk '{print $1}'))

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
    crontab chaosmonkey_job
    rm chaosmonkey_job
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
    for namespace in "${ALL_KUBERNETES_NAMESPACES[@]}"
    do
        for config_namespaces in "${CONFIG_NAMESPACE_LIST[@]}"
        do
            if [[ $config_namespaces == $namespace ]];
            then
                TO_BE_DELETED+=( $namespace )
            fi
        done
    done

    for del in ${TO_BE_DELETED[@]}
    do
        ALL_KUBERNETES_NAMESPACES=("${ALL_KUBERNETES_NAMESPACES[@]/$del}")
    done

    info_output "Target Namespaces: "
    echo "|_____"${ALL_KUBERNETES_NAMESPACES[@]}
fi


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
            echo "${CONFIG_PERIOD_NUMBER} * * * * source $HOME/chaosmonkey-app/chaosmonkey.sh" > chaosmonkey_job
            activate_cronjob
        fi
        ;;

    "h")
        if [[ $CONFIG_PERIOD_NUMBER -lt 24 ]];
        then
            info_output "Pods where automatically killed every "$CONFIG_PERIOD_NUMBER$CONFIG_PERIOD_UNIT
            echo "* ${CONFIG_PERIOD_NUMBER} * * * source $HOME/chaosmonkey-app/chaosmonkey.sh" > chaosmonkey_job
            activate_cronjob
        fi
        ;;

    "d")
        if [[ $CONFIG_PERIOD_NUMBER -lt 32 ]]
        then
            info_output "Pods where automatically killed every "$CONFIG_PERIOD_NUMBER$CONFIG_PERIOD_UNIT
            echo "* * ${CONFIG_PERIOD_NUMBER} * * source $HOME/chaosmonkey-app/chaosmonkey.sh" > chaosmonkey_job
            activate_cronjob
        fi
        ;;

    *)
        invalid_input_error $CONFIG_PERIOD_UNIT
        exit
        ;;
esac



##write out current crontab
#crontab -l > mycron
##echo new cron into cron file
#echo "00 09 * * 1-5 echo hello" >> mycron
##install new cron file
#crontab mycron
#rm mycron









######## KILL PODS:
# target namespace: ALL_KUBERNETES_NAMESPACES
# 