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
doctl auth init -t $(cat /home/chaosmonkey/do_token)

# Call "get_kubeconfig" script to get the current kubeconfig of all DigitalOcean
# kubernetes cluster
source get_kubeconfig.sh