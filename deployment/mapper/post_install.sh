#!/bin/bash
set -x
set -e

#
# For Ubuntu distribution Version 16.04 LTS
#

INSTAL4J_LICENSE_KEY=${1?"Provide Install4j license key."}

source ../lib.sh
source /opt/slipstream/client/sbin/slipstream.setenv

S3_HOST=`ss-get s3-host`
S3_BUCKET=`ss-get s3-bucket`
S3_ACCESS_KEY=`ss-get s3-access-key`
S3_SECRET_KEY=`ss-get s3-secret-key`

install_S1_toolbox() {

    # MAVEN_HOME=/usr/bin/mvn
    # export MAVEN_HOME
    #PATH=$PATH:$MAVEN_HOME/bin
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME
    PATH=$PATH:$JAVA_HOME/bin
    #s3cmd get s3://eodata/esa-snap_sentinel_unix_5_0.sh
    curl -O http://step.esa.int/downloads/5.0/installers/esa-snap_sentinel_unix_5_0.sh
    chmod +x esa-snap_sentinel_unix_5_0.sh

    echo -e "o\n1\n\n\n2,3\ny\n\ny\n\ny\n" | ./esa-snap_sentinel_unix_5_0.sh
    #
    # cd /home
    #
    # git clone https://github.com/senbox-org/s1tbx.git
    # git clone https://github.com/senbox-org/snap-engine.git
    # git clone https://github.com/senbox-org/snap-installer.git
    # git clone https://github.com/senbox-org/snap-desktop.git
    #
    # cd snap-engine
    # mvn clean install -U -Dmaven.test.skip=true
    #
    # cd ../snap-desktop
    # mvn clean install -U -Dmaven.test.skip=true
    #
    # cd snap-application
    # mvn clean install -U -Dmaven.test.skip=true
    #
    # cd ../../s1tbx
    # mvn clean install -U -Dmaven.test.skip=true
    #
    # cd ../snap-installer
    # mvn clean install -U -Dmaven.test.skip=true
    #
    # wget http://download-keycdn.ej-technologies.com/install4j/install4j_linux_6_1_5.deb
    # dpkg -i install4j_linux_6_1_5.deb
    #
    # cp -rp jres/* /opt/install4j6/jres
    #
    # install4jc -L $INSTAL4J_LICENSE_KEY
    # install4jc snap.install4j -m unixInstaller
    #
    # chmod +x target/esa-snap_all_unix_6_0-SNAPSHOT.sh
    # (printf 'o\n1\n\n\nX,2,3\ny\n\ny\n\ny\n') | \
    #     /home/snap-installer/target/esa-snap_all_unix_6_0-SNAPSHOT.sh


}

set_x11() {
#set up to display products on remote ssh machine through X11
echo -e "ForwardX11 yes\nForwardX11Trusted yes\n" >> /etc/ssh/ssh_config
Xvfb :1
export DISPLAY=:1
}

configure_python_interface() {
    #TODO: check if SNAP is correctly installed
    cd /opt/snap/bin
    ./snappy-conf /usr/bin/python2.7 #/home/snap-engine/snap-python/src/main/resources/snappy

    cd /opt/snap/snap/modules/lib/x86_64/
    ln -s ../amd64/libjhdf.so
    ln -s ../amd64/libjhdf5.so
}


config_s3 $S3_HOST $S3_ACCESS_KEY $S3_SECRET_KEY
install_S1_toolbox
set_x11 &
configure_python_interface
echo $?
#install_slipstream_api
