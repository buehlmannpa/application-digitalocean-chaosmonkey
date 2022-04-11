#!/bin/bash
# This script connects to all kubernetes cluster and provides the kubeconfig of each cluster
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



#doctl auth init -t $(cat /home/chaosmonkey/do_token)

doctl kubernetes cluster kubeconfig save k8s-cluter-c1-fra1-1227
