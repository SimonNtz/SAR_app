#!/bin/bash
set -x
set -e

#
# For Ubuntu distribution Version 16.04 LTS
#

INSTAL4J_LICENSE_KEY=${1?"Provide Install4j license key."}

source ../lib.sh

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

    cp -rp jres/* /opt/install4j6/jres

    install4jc -L $INSTAL4J_LICENSE_KEY
    install4jc snap.install4j -m unixInstaller

    chmod +x target/esa-snap_all_unix_6_0-SNAPSHOT.sh
    (printf 'o\n1\n\n\nX,2,3\ny\n\ny\n\ny\n') | \
        /home/snap-installer/target/esa-snap_all_unix_6_0-SNAPSHOT.sh
}

configure_python_interface() {
    #TODO: check if SNAP is correctly installed
    apt install -y strace
    bash /opt/snap/bin/snap --nogui --nosplash --python /usr/bin/python2.7 \
        /home/snap-engine/snap-python/src/main/resources/snappy
    if [ $? ne 0 ]; then
    bash /opt/snap/bin/snap --nogui --nosplash --python /usr/bin/python2.7 \
            /home/snap-engine/snap-python/src/main/resources/snappy
    fi

    # VERIF SNAPPY INTERFACE
    cd /opt/snap/snap/modules/lib/x86_64/
    ln -s ../amd64/libjhdf.so
    ln -s ../amd64/libjhdf5.so
}

install_S1_toolbox
configure_python_interface
echo $?
#install_slipstream_api
