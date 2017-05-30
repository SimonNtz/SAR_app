#!/bin/bash

set -o pipefail

# Bash script launching the the SlipStream application.
# Its unique parameter is the cloud service selected by the client.
# It retrieves the input list from file "product_list.cfg".

# Connector instance name as defined on https://nuv.la for which user has
# provided credentials in its profile.
CLOUD="$1"

INPUT_SIZE=`awk '/^[a-zA-z]/' product_list.cfg | wc -l`
INPUT_LIST=`awk '/^[a-zA-z]/' product_list.cfg`

trap 'rm -f $LOG' EXIT

LOG=`mktemp`
SS_ENDPOINT=https://nuv.la

python -u `which ss-execute` \
    --endpoint $SS_ENDPOINT \
    --wait 30 \
    --keep-running="never" \
    --parameters="
    mapper:multiplicity=$INPUT_SIZE,
    mapper:product-list=$INPUT_LIST,
    mapper:cloudservice=$CLOUD,
    reducer:cloudservice=$CLOUD" \
    EO_Sentinel_1/procSAR 2>&1 | tee $LOG

if [ "$?" == "0" ]; then
    run=`awk '/::: Waiting/ {print $7}' $LOG`
    echo "::: URL with the computed result:"
    curl -u $SLIPSTREAM_USERNAME:$SLIPSTREAM_PASSWORD \
        $run/reducer.1:url.service
    echo
fi
