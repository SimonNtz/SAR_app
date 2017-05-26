#!/env/bin bash

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
#nuv.la	FALSE	/	TRUE	1495616337	com.sixsq.slipstream.cookie	token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InNpbW9uMTk5MiIsInJvbGVzIjoiVVNFUiBBTk9OIiwiZXhwIjoxNDk1NjE2MzM3fQ.SRdnhjIJuRu66MXKSUkUrwIh8_NGggG2plhg9RwxuPt2PZv1BMKmeBYPDuFE9gCl5sVMImDA4HLV8X5e2LSAbfkFIhBcm9B_7kCu0x9ZkwAo7mmeurC6JBwUg3n4PMTYnX-Cz_UeSgxYjbT-C7RhGQT0cKog9ZOL538vdktuG6WuLUEp8IpyrVKKc5yOTvXmK71s0tO1hhf-IEq7hd31CHmO__1iRA1wcxt1Bl2Kn4rkSNb_JOBfyQw__lv-Y3gGk2YOev5ly5rX5JySIUCGtKCfmPmrj4zIV5_UYGFl_o2PdmMOIRNK0GIR7wlpTN0uIyawKabr2YcwRvCA8OFOdA
EOF
}

set_s3
#install_slipstream_api
#create_cookie "`ss-get nuvla_token`"

sudo rm -rf /var/lib/cloud/instance/sem/*
