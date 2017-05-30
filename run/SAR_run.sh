#!/bin/bash

# - Bash script launching the the SlipStream application
# - its unique parameter is the cloud service selected by the client
# - it retrieves the input list from file "product_list.cfg"

# Connector instance name as defined on https://nuv.la for which user has
# provided credentials in its profile.
CLOUD="$1"

INPUT_SIZE=`awk '/^[a-zA-z]/' product_list.cfg | wc -l`
INPUT_LIST=`awk '/^[a-zA-z]/' product_list.cfg`

ss-execute \
    --keep-running="never" \
    --parameters="
    mapper:multiplicity=$INPUT_SIZE,
    mapper:product-list=$INPUT_LIST,
    mapper:cloudservice=$CLOUD,
    reducer:cloudservice=$CLOUD" \
    EO_Sentinel_1/procSAR
