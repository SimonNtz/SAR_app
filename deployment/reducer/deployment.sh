#!/bin/bash

set -e
set -x
set -o pipefail

source ../lib.sh

S3_HOST=`ss-get s3-host`
S3_BUCKET=`ss-get s3-bucket`
S3_ACCESS_KEY=`ss-get s3-access-key`
S3_SECRET_KEY=`ss-get s3-secret-key`

set_listeners() {
    # Lauch netcat daemons for each  product
    echo -n  $@ | xargs -d ' ' -I% bash -c '(nc -l 808%  0<&- 1>%.png) &'
}

check_mappers_ready() {
    # Run multiple daemons depending on the mapper VM multiplicity and
    # whithin these a timeout checking mapper's ready state is triggered.

    echo -n $ids | xargs -d ' ' -I% bash -c '(
    ss-get --timeout 1800 mapper.%:ready
    echo 'mapper.'%':ready' >>readylock.md
    exit 0) &'
}

count_ready() {
    # The number of line existing in "readylock.md" file indicates
    # how many mappers are is in ready state.
    echo `cat readylock.md | wc -l`
}

wait_mappers_ready() {
    touch readylock.md
    ids=`ss-get --noblock mapper:ids | sed -e 's/,/ /g'`
    set_listeners $ids
    check_mappers_ready
    # Wait before all mappers are in ready state.
    while [ $(count_ready) -ne `ss-get mapper:multiplicity` ]; do
        sleep 100
    done
}

create_cookie "`ss-get --noblock nuvla_token`"

wait_mappers_ready
post_event "Reducer has finished to download corrected product."


# Create the final output
SAR_convert=SAR_convert`ss-get converter`.sh
cd ~/SAR_proc/reducer/
./$SAR_convert
