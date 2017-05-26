#!/bin/bash
cd /home


set_s3() {

S3_CFG=~/.s3cfg
# S3_BUCKET=s3://eodata_output

    cat > $S3_CFG <<EOF

    host_base = sos.exo.io
    host_bucket = %(bucket)s.sos.exo.io

    access_key = $$
    secret_key = $$
    use_https = True
    signature_v2 = True

EOF

#(printf '\n\n\n\n\n\n\n\ny') | s3cmd --configure

}

install_slipstream_api(){
    pip install https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream /usr/local/lib/python2.7/dist-packages/slipstream
}

cookiefile=/home/cookies-nuvla.txt

create_cookie(){
  [ -z "$@" ] || return
    cat >cookies-nuvla.txt<<EOF
# Netscape HTTP Cookie File
# http://curl.haxx.se/rfc/cookie_spec.html
# This is a generated file!  Do not edit.

"$@"
EOF
}

post_event() {
  [ -f $cookiefile ] || return
  username=$(get_username)
  cat >pyScript.py<<EOF
import sys
from slipstream.api import Api
api = Api(cookie_file='$cookiefile')
log = str(sys.argv[1]).translate(None, "[]")
print log
event = {'acl': {u'owner': {u'principal': u'$username'.strip(), u'type': u'USER'},
        u'rules': [{u'principal': u'$username'.strip(),
        u'right': u'ALL',
        u'type': u'USER'},
        {u'principal': u'ADMIN',
        u'right': u'ALL',
        u'type': u'ROLE'}]},
  'content': {u'resource': {u'href': u'run/'+ '$(get_DUIID)'},
                                        u'state': log},
  'severity': u'low',
  'timestamp': '$(get_timestamp)',
  'type': u'state'}

api.cimi_add('events', event)
EOF
python pyScript.py "$@"
}

get_DUIID() {
    awk -F= '/diid/ {print $2}'
        /opt/slipstream/client/sbin/slipstream.context
}

get_timestamp() {
    echo `date --utc +%FT%T.%3NZ`
}

get_username() {
  awk -F= '/username/ {print $2}'
      /opt/slipstream/client/sbin/slipstream.context
}

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
#mv /home/ubuntu/.s3cfg /root/
install_slipstream_api
# Push animated GIF to the object store through S3
s3cmd put $output $S3_BUCKET
ss-set ss:url.service https://sos.exo.io/eodata_output/$output
post_event 'Output file available on object store'
ss-set ready true
