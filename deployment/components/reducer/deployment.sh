#!/bin/bash
cd /home
set -e
set -x
set -o pipefail

curl -o 


# TODO: to RTP.
S3_BUCKET=s3://eodata_output

# Lauch netcat daemons for each  product
set_listeners() {
echo -n  $@ | xargs -d ' ' -I% bash -c '(nc -l 808%  0<&- 1>%.png) &'
}

# Run multiple daemons depending on the mapper VM multiplicity and
# whithin these a timeout checking mapper's ready state is triggered.

check_ready() {
    echo -n $ids | xargs -d ' ' -I% bash -c '(
    ss-get --timeout 1800 mapper.%:ready
    echo 'mapper.'%':ready' >>readylock.md
    exit 0) &'
}

# The number of line existing in "readylock.md" file indicates
# how many mappers are is ready state.

count_ready() {
   echo `cat readylock.md | wc -l`
}

ids=`ss-get --noblock mapper:ids | sed -e 's/,/ /g'`

timestamp=$(date +%s)
output=SAR_animation_$timestamp.gif

touch readylock.md


if [ -z "$ids" ]; then
   ss-display "No mappers provisioned. Skipping this time."
else
   set_listeners $ids
   check_ready
   create_cookie "`ss-get --noblock nuvla_token`"
  #  install_slipstream_api
  #  cat cookies-nuvla.txt

  # Wait before all mappers are in ready state i.e. equals to mappers' multiplicity integer
   while [ $(count_ready) -ne `ss-get mapper:multiplicity` ]; do sleep 100; done

   post_event "Reducer has finished to download corrected product"
  # Create the final output
   ls -l *.png
   convert -delay 20 -loop 0 *.png $output
fi

#set_s3
# TODO Move this line to post_install
mv /home/ubuntu/.s3cfg /root/
install_slipstream_api
# Push animated GIF to the object store through S3
s3cmd put $output $S3_BUCKET
ss-set ss:url.service https://sos.exo.io/eodata_output/$output
post_event 'Output file available on object store'
ss-set ready true
