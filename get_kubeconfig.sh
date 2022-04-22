#!/bin/bash
# This script connects to all kubernetes cluster and provides the kubeconfig of each cluster
# Copyright 2022 Patrick Bühlmann
#
#----------------------------------------------------------------------------------------------
# IMPLEMENTATION
#   version         0.0.2
#   author          Patrick Bühlmann
#   copyright       Copyright (c) www.patrick21.ch
#   license         GNU General Public License
#
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------
# var declaration
#----------------------------------------------------------------------------------------------
DOWNLOAD_DIR="/home/chaosmonkey/download"

ALL_KUBECTL_CONTEXTS=($(kubectl config get-contexts | grep -v "NAME" |awk '{print $2}'))
ALL_KUBECTL_CONTEXTS_LENGTH=${#ALL_KUBECTL_CONTEXTS[@]}


#----------------------------------------------------------------------------------------------
# Kubeconfig for multiple cluster
# If the chaos-monkey needs to maintain more the two cluster's feel free to 
# add more clusters to the list below
#----------------------------------------------------------------------------------------------

if [[ ALL_KUBECTL_CONTEXTS_LENGTH -eq 0 ]];
then
    $DOWNLOAD_DIR/doctl kubernetes cluster kubeconfig save k8s-cluter-c1-fra1-1227
    $DOWNLOAD_DIR/doctl kubernetes cluster kubeconfig save k8s-cluter-c2-fra1-1227
    # to add more clusters copy & paste the line above and edit the cluster name

else
    # input: 1 = cluster 1
    #        2 = cluster 2
    kubectl config use-context ${ALL_KUBECTL_CONTEXTS[$1]}
fi
