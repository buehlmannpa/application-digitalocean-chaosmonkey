#!/bin/bash
# This script fully clean a node and disable sheduling. 
# !IMPORTANT: This script has no automation and must be executed manually
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
NODE_LIST=($(kubectl get nodes |grep -v NAME |awk '{print $1}'))

NOCOLOR='\033[0m'
LIGHTGREEN='\033[1;32m'

#----------------------------------------------------------------------------------------------
# PART: Output node list and read Node
#----------------------------------------------------------------------------------------------
echo -e "${LIGHTGREEN}Copy and past one of the following nodes to clean${NOCOLOR}"
for node in "${NODE_LIST[@]}"
do
    echo "$node"
done

echo ""
echo -e "${LIGHTGREEN}Please copy&paste one of the nodes above${NOCOLOR}"
read NODE  


#----------------------------------------------------------------------------------------------
# PART: Drain or undrain node
#----------------------------------------------------------------------------------------------
# Node state: Ready 
#             Ready,SchedulingDisabled

NODE_STATE=$(kubectl get nodes |grep $NODE |awk '{print $2}')

if [[ "$NODE_STATE" == "Ready" ]];
then
    kubectl drain $NODE --delete-emptydir-data --ignore-daemonsets
    echo -e "${LIGHTGREEN}DONE - Node is drained and marked as SchedulingDisabled${NOCOLOR}"
elif [[ "$NODE_STATE" == "Ready,SchedulingDisabled" ]];
then
    kubectl uncordon $NODE
else
    echo "Node state is not what script is expecting"
fi
