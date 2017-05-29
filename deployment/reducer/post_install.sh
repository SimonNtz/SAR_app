#!/env/bin bash

set -e
set -x

set_s3() {
    S3_CFG=~/.s3cfg
    cat > $S3_CFG <<EOF
    host_base = sos.exo.io
    host_bucket = %(bucket)s.sos.exo.io

    access_key = $S3_ACCESS_KEY
    secret_key = $S3_SECRET_KEY
    use_https = True
    signature_v2 = True

EOF

(printf '\n\n\n\n\n\n\n\ny') | s3cmd --configure

}

install_slipstream_api(){
    pip install https://github.com/slipstream/SlipStreamPythonAPI/archive/master.zip
    mv /usr/local/lib/python2.7/dist-packages/slipstream/api /opt/slipstream/client/lib/slipstream/
    rm -Rf /usr/local/lib/python2.7/dist-packages/slipstream
    ln -s /opt/slipstream/client/lib/slipstream /usr/local/lib/python2.7/dist-packages/slipstream
}


create_cookie(){
    cat >cookies-nuvla.txt<<EOF
# Netscape HTTP Cookie File
# http://curl.haxx.se/rfc/cookie_spec.html
# This is a generated file!  Do not edit.

"$@"
EOF
}

set_s3
#install_slipstream_api
#create_cookie "`ss-get nuvla_token`"

sudo rm -rf /var/lib/cloud/instance/sem/*
