# Library functions for deployment.

config_s3() {
    cat > ~/.s3cfg <<EOF
[default]
host_base = $1
host_bucket = %(bucket)s.$1

access_key = $2
secret_key = $3

use_https = True
EOF
    if [ "$1" == "sos.exo.io" ] ;then
        cat >>~/.s3cfg<<EOF
# For Exoscale only
signature_v2 = True
EOF
     fi
}

#
# Eventing.
# Retrieve the client's Nuvla token through the application component parameters

cookiefile=/home/cookies-nuvla.txt

install_slipstream_api(){
    pip install \
        https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api \
        /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream \
        /usr/local/lib/python2.7/dist-packages/slipstream
}

create_cookie(){
    [ -z "$@" ] || return
    cat >$cookiefile<<EOF
# Netscape HTTP Cookie File

$@
EOF
}

get_DUIID() {
    awk -F= '/diid/ {print $2}' \
        /opt/slipstream/client/sbin/slipstream.context
}

get_ss_user() {
    awk -F= '/username/ {print $2}' \
        /opt/slipstream/client/sbin/slipstream.context
}

post_event() {
    msg=$@
    [ -f $cookiefile ] || return
    username=$(get_ss_user)
    duiid=$(get_DUIID)
    event_script=/tmp/post-event.py
    [ -f $event_script ] || \
         cat >$event_script<<EOF
import sys
from slipstream.api import Api
import datetime
api = Api(cookie_file='$cookiefile')
msg = str(sys.argv[1]).translate(None, "[]")
print msg
event = {'acl': {u'owner': {u'principal': u'$username'.strip(), u'type': u'USER'},
        u'rules': [{u'principal': u'$username'.strip(),
        u'right': u'ALL',
        u'type': u'USER'},
        {u'principal': u'ADMIN',
        u'right': u'ALL',
        u'type': u'ROLE'}]},
  'content': {u'resource': {u'href': u'run/'+ u'$duuid'.strip()},
                                        u'state': msg},
  'severity': u'low',
  'timestamp': '%sZ' % datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3],
  'type': u'state'}

api.cimi_add('events', event)
EOF
    python $event_script "$msg"
}

