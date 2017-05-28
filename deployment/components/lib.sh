# Lib functions for deployment.

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

