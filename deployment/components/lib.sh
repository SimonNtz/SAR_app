# Library functions for deployment.

config_s3() {
    cat > ~/.s3cfg <<EOF
[default]
host_base = $1
host_bucket = %(bucket)s.$1

access_key = $2
secret_key = $3

use_https = True
# For Exoscale only
signature_v2 = True
EOF
}

get_file_github() {
    ghproject=https://raw.githubusercontent.com/SimonNtz/SAR_app/${GH_BRANCH-master}
    file_gh=${1?"Path to file on GitHub should be provided."}
    file_local=${2-$(basename $file_gh)}
    curl -o $file_local -sSfL $ghproject/$file_gh
}

install_slipstream_api(){
    pip install \
        https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api \
        /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream \
        /usr/local/lib/python2.7/dist-packages/slipstream
}


#
# Eventing.
# Retrieve the client's Nuvla token through the application component parameters

cookiefile=/home/cookies-nuvla.txt

create_cookie(){
    [ -z "$@" ] || return
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

