#!/bin/bash

#TODO verify SS-client install

#Recover token in cookies-nuvla.txt
slipstream login -u $SLIPSTREAM_USERNAME -p $SLIPSTREAM_PASSWORD

NUVLA_TOKEN=`cat ~/.slipstream/cookies-nuvla.txt | grep -v \#`

CLOUD="$1"
#CLOUD='eo-cesnet-cz1'
#CLOUD='ec2-eu-west'

INPUT_SIZE=`cat product_list.cfg |sed '/^\s*#/d;/^\s*$/d' | wc -l`
INPUT_LIST=`cat product_list.cfg`

ss-execute --parameters="mapper:multiplicity=$INPUT_SIZE","mapper:product_url='$INPUT_LIST'","mapper:cloudservice=$CLOUD","reducer:cloudservice=$CLOUD","reducer:nuvla_token='$NUVLA_TOKEN'" --keep-running="always" EO_Sentinel_1/procSAR
#ss-execute --parameters="mapper:multiplicity=3","mapper:product_url='$INPUT_LIST'","mapper:cloudservice=eo-cesnet-cz1","reducer:cloudservice=eo-cesnet-cz1" EO_Sentinel_1/procSAR
