#!/bin/bash

#
# For Ubuntu distribution Version 16.04 LTS
#

set -e
set -x
set -o pipefail


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


S3_CFG=~/.s3cfg
S3_BUCKET=s3://eodata
set_s3() {

    #apt-get -y install s3cmd
    cat > $S3_CFG <<EOF

    [default]
    host_base = sos.exo.io
    host_bucket = %(bucket)s.sos.exo.io

    access_key = $$
    secret_key = $$

    use_https = True
    signature_v2 = True

EOF

(printf '\n\n\n\n\n\n\n\ny') | s3cmd --configure

}

get_data() {

    #curl -o sarget.sh -sSfL $gh/SimonNtz/SAR_app/$branch/app/sarget.sh
    #for i in ${my_product[@]}; do
        #bash sarget.sh -u SimonNtz -p mario1992 -F $i -o product -O /home/data
    #done
    echo $(date)
    for i in ${my_product[@]}; do
        s3cmd get --recursive $S3_BUCKET/$i.SAFE
    done
    echo $(date)
    #unzip $i.zip

}

run_proc() {
   curl -o SAR_test_proc.py -sSfL $gh/SimonNtz/SAR_app/$branch/app/SAR_test_proc.py
   echo "java_max_mem: 14G" >> /home/snap-engine/snap-python/src/main/resources/snappy/snappy/snappy.ini
   #TODO check if SAR_data is not empty!
    for i in ${my_product[@]}; do
           python SAR_test_proc.py $i
    done
    find /home/data/ -maxdepth 1 -name *.png -exec cp {} $id.png \;
   #TODO clear .snap/var/temp/cache files
}


#Push product to reducer using netcat
push_product() {
    nc $reducer_ip 808$id < $id.png
}

install_slipstream_api(){
    pip install https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream /usr/local/lib/python2.7/dist-packages/slipstream
}

# HARDCODED cookie
create_cookie(){
    cat >cookies-nuvla.txt<<EOF
# Netscape HTTP Cookie File
# http://curl.haxx.se/rfc/cookie_spec.html
# This is a generated file!  Do not edit.

"$@"
#nuv.la	FALSE	/	TRUE	1495616337	com.sixsq.slipstream.cookie	token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InNpbW9uMTk5MiIsInJvbGVzIjoiVVNFUiBBTk9OIiwiZXhwIjoxNDk1NjE2MzM3fQ.SRdnhjIJuRu66MXKSUkUrwIh8_NGggG2plhg9RwxuPt2PZv1BMKmeBYPDuFE9gCl5sVMImDA4HLV8X5e2LSAbfkFIhBcm9B_7kCu0x9ZkwAo7mmeurC6JBwUg3n4PMTYnX-Cz_UeSgxYjbT-C7RhGQT0cKog9ZOL538vdktuG6WuLUEp8IpyrVKKc5yOTvXmK71s0tO1hhf-IEq7hd31CHmO__1iRA1wcxt1Bl2Kn4rkSNb_JOBfyQw__lv-Y3gGk2YOev5ly5rX5JySIUCGtKCfmPmrj4zIV5_UYGFl_o2PdmMOIRNK0GIR7wlpTN0uIyawKabr2YcwRvCA8OFOdA
EOF
}

# Require 'cookies-nuvla.txt' to exist and be valid
post_event() {
    cat >pyScript.py<<EOF
import sys
from slipstream.api import Api
api = Api(cookie_file='/home/cookies-nuvla.txt')
log = str(sys.argv[1]).translate(None, "[]")
print log
event = {'acl': {u'owner': {u'principal': u'simon1992', u'type': u'USER'},
        u'rules': [{u'principal': u'simon1992',
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
    foo=`(cat /opt/slipstream/client/sbin/slipstream.context | grep 'diid')`
    echo "$foo" | awk '{print $3}'
}

get_timestamp() {
    echo `date --utc +%FT%T.%3NZ`
}

reducer_ip=`ss-get reducer:hostname`

create_cookie "`ss-get reducer:nuvla_token`"
install_slipstream_api
cat cookies-nuvla.txt
set_s3
post_event "mapper.$id: starts downloading $my_product"
get_data
post_event "mapper.$id: starts image processing"
run_proc
post_event "mapper.$id: is sending output to reducer"
push_product
ss-set ready true
