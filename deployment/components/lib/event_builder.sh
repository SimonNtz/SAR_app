
install_slipstream_api(){
    pip install https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream /usr/local/lib/python2.7/dist-packages/slipstream
}

create_cookie(){
    cat >$cookiefile<<EOF
# Netscape HTTP Cookie File
# http://curl.haxx.se/rfc/cookie_spec.html
# This is a generated file!  Do not edit.
EOF
}

post_event() {
    cat >pyScript.py<<EOF
import sys
from slipstream.api import Api
api = Api(cookie_file='/home/cookies-nuvla.txt')
log = str(sys.argv[1]).translate(None, "[]")
print log
event = {'acl': {u'owner': {u'principal': u'simon1992 , u'type': u'USER'},
        u'rules': [{u'principal': u'simon1992,
        u'right': u'ALL',
        u'type': u'USER'},
        {u'principal': u'ADMIN',
        u'right': u'ALL',
        u'type': u'ROLE'}]},
  'content': {u'resource': {u'href': u'run/'+ u'4cdcdd3a-7c73-46c9-9245-e358edca3cf2'},
                                        u'state': log},
  'severity': u'low',
  'timestamp': '$(get_timestamp)',
  'type': u'state'}

api.cimi_add('events', event)
EOF
python pyScript.py "$@"
}

get_DUIID() {
    awk -F= '/diid/ {print $2}' /opt/slipstream/client/sbin/slipstream.context
}

get_username() {
  awk -F= '/username/ {print $2}' /opt/slipstream/client/sbin/slipstream.context
}

get_timestamp() {
    echo `date --utc +%FT%T.%3NZ`
}
