#!/bin/bash
# *** CLIENT SCRIPT ***
#
# - Bash script launching the the SlipStream application
# - its unique parameter is the cloud service selected by the client
# - it retrieves the input list from file "product_list.cfg"
#

#Recover token in cookies-nuvla.txt
slipstream login -u $SLIPSTREAM_USERNAME -p $SLIPSTREAM_PASSWORD

NUVLA_TOKEN=`cat ~/.slipstream/cookies-nuvla.txt | grep -v \#`

CLOUD="$1"
#CLOUD='eo-cesnet-cz1'
#CLOUD='ec2-eu-west'

INPUT_SIZE=`cat product_list.cfg | sed '/^\s*#/d;/^\s*$/d' | wc -l`
INPUT_LIST=`cat product_list.cfg | sed '/^\s*#/d;/^\s*$/d'`

ss-execute \
    --keep-running="always" \
    --parameters="
    mapper:multiplicity=$INPUT_SIZE,
    mapper:product_url=$INPUT_LIST,
    mapper:cloudservice=$CLOUD,
    reducer:cloudservice=$CLOUD,
    reducer:nuvla_token=$NUVLA_TOKEN" \
    EO_Sentinel_1/procSAR
