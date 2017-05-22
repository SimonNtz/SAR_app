#!/bin/bash

#
# For Ubuntu distribution Version 16.04 LTS
#


#riemann_host=`ss-get autoscaler_hostname`
#riemann_port=5555

install_S1_toolbox() {

MAVEN_HOME=/usr/bin/mvn
export MAVEN_HOME
PATH=$PATH:$MAVEN_HOME/bin
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export JAVA_HOME
PATH=$PATH:$JAVA_HOME/bin

cd /home

git clone https://github.com/senbox-org/s1tbx.git
git clone https://github.com/senbox-org/snap-engine.git
git clone https://github.com/senbox-org/snap-installer.git
git clone https://github.com/senbox-org/snap-desktop.git

cd snap-engine
mvn clean install -U -Dmaven.test.skip=true

cd ../snap-desktop
mvn clean install -U -Dmaven.test.skip=true

cd snap-application
mvn clean install -U -Dmaven.test.skip=true

cd ../../s1tbx
mvn clean install -U -Dmaven.test.skip=true

cd ../snap-installer
mvn clean install -U -Dmaven.test.skip=true

wget http://download-keycdn.ej-technologies.com/install4j/install4j_linux_6_1_5.deb
dpkg -i install4j_linux_6_1_5.deb

# TRIAL_KEY='E-M6-SIMON#842657-2017.06.26-90-332ybvu3qrrty9#2938'

cp -rp jres/* /opt/install4j6/jres

install4jc -L $INSTAL4j_TRIAL_KEY
install4jc snap.install4j -m unixInstaller

chmod +x target/esa-snap_all_unix_6_0-SNAPSHOT.sh
(printf 'o\n1\n\n\nX,2,3\ny\n\ny\n\ny\n') | /home/snap-installer/target/esa-snap_all_unix_6_0-SNAPSHOT.sh
}

configure_python_interface() {
#TODO: check if SNAP is correctly installed
bash /opt/snap/bin/snap --nogui --nosplash --python /usr/bin/python2.7  /home/snap-engine/snap-python/src/main/resources/snappy
# VERIF SNAPPY INTERFACE
cd /opt/snap/snap/modules/lib/x86_64/
ln -s ../amd64/libjhdf.so
ln -s ../amd64/libjhdf5.so
}

deploy_and_run_riemann_client() {
    pip install --upgrade pip
    yum install -y python-pip python-devel gcc zeromq-devel
    pip install pyzmq
    pip install --upgrade six

    # Due to https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=835688
    pip install protobuf==3.1.0
    pip install riemann-client==6.3.0
#    source_location=${source_root}/nginx/deployment

    curl -sSf -o ~/nginx_riemann_sender.py $source_location/nginx_riemann_sender.py

    # Autoscaler ready synchronization flag!
#    ss-display "Waiting for Riemann to be ready."
#    ss-get --timeout 600 autoscaler_ready

#    chmod +x ~/nginx_riemann_sender.py
#    ~/nginx_riemann_sender.py $riemann_host:$riemann_port &
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

set_s3() {
    S3_CFG=~/.s3cfg
    #S3_BUCKET=s3://eodata
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

install_S1_toolbox
configure_python_interface
set_S3
create_cookie "`ss-get nuvla_token`"
install_slipstream_api
