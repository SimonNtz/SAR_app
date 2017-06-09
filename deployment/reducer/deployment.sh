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
output=SAR_animation_$(date +%s).gif
convert -delay 50 -loop 0 *.png $output
post_event 'Converted input into result.'

# Push animated GIF to the object store through S3.
config_s3 $S3_HOST $S3_ACCESS_KEY $S3_SECRET_KEY
cp $output /var/log/slipstream/client/
#s3cmd put $output s3://$S3_BUCKET
#ss-set ss:url.service https://$S3_HOST/$S3_BUCKET/$output
post_event 'Pushed result to object store.'

ss-set ready true
