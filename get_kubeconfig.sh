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


#----------------------------------------------------------------------------------------------
# Kubeconfig for one single cluster
#----------------------------------------------------------------------------------------------
doctl kubernetes cluster kubeconfig save k8s-cluter-c1-fra1-1227
