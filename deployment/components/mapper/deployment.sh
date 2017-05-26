#!/bin/bash
set -e
set -x
set -o pipefail

#
# For Ubuntu distribution Version 16.04 LTS
#

gh=https://raw.githubusercontent.com
branch=master

workspace=/home/data
mkdir -p $workspace
cd $workspace
echo 'TEST'
id=`ss-get id`
# full list of product
SAR_data=(`ss-get product_url`)
my_product=${SAR_data[$id-1]}

IFS=' ' read -r -a my_product <<< "$my_product"
echo ${my_product[@]}

S3_BUCKET=s3://eodata
S3_ACCESS_KEY=
S3_SECRET_KEY=

set_s3() {
    cat > ~/.s3cfg <<EOF
[default]
host_base = sos.exo.io
host_bucket = %(bucket)s.sos.exo.io

access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY

use_https = True
signature_v2 = True
EOF
}

get_data() {

    echo $(date)
    for i in ${my_product[@]}; do
        sudo s3cmd get --recursive $S3_BUCKET/$i.SAFE
    done
    echo $(date)

}

run_proc() {
   curl -o SAR_proc.py -sSfL $gh/SimonNtz/SAR_app/$branch/app/SAR_proc.py
   echo "java_max_mem: 14G" >> /home/snap-engine/snap-python/src/main/resources/snappy/snappy/snappy.ini
   #TODO check if SAR_data is not empty!
    for i in ${my_product[@]}; do
           python SAR_proc.py $i
    done
    find /home/data/ -maxdepth 1 -name *.png -exec cp {} $id.png \;
   #TODO clear .snap/var/temp/cache files
}

push_product() {
    nc $reducer_ip 808$id < $id.png
}

install_slipstream_api(){
    pip install https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream /usr/local/lib/python2.7/dist-packages/slipstream
}

# Retrieve the client's Nuvla token through the application component parameters

cookiefile=/home/cookies-nuvla.txt

create_cookie(){
#    [ -z "$@" ] || return
    cat >$cookiefile<<EOF
# Netscape HTTP Cookie File
"$1"
EOF
}

get_DUIID() {
    awk -F= '/diid/ {print $2}' /opt/slipstream/client/sbin/slipstream.context
}

get_timestamp() {
    echo `date --utc +%FT%T.%3NZ`
}

get_username() {
  awk -F= '/username/ {print $2}' /opt/slipstream/client/sbin/slipstream.context
}

post_event() {
  [ -f $cookiefile ] || return
  username=$(get_username)
  duiid=$(get_DUIID)
  event=post-event.py
  cat >$event<<EOF
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
  'content': {u'resource': {u'href': u'run/'+ u'$get_DUIID'.strip()},
                                        u'state': log},
  'severity': u'low',
  'timestamp': '$(get_timestamp)',
  'type': u'state'}

api.cimi_add('events', event)
EOF
    python $event "$@"
}

reducer_ip=`ss-get reducer:hostname`
create_cookie "`ss-get --noblock reducer:nuvla_token`"
set_s3
install_slipstream_api
post_event "mapper.$id: starts downloading $my_product"
get_data
post_event "mapper.$id: starts image processing"
run_proc
post_event "mapper.$id: is sending output to reducer"
push_product
ss-set ready true
