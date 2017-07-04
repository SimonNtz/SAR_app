#!/bin/bash
set -x
set -e
set -o pipefail

#
# Functional on Ubuntu distribution Version 16.04 LTS
#

install_S1_toolbox() {

    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME
    PATH=$PATH:$JAVA_HOME/bin
    SNAP_LOC=/usr/local/snap
    SNAP_INSTALLER=esa-snap_sentinel_unix_5_0.sh

    # Impose the SNAP installation output directory
    # b.c. the cloud service can change it deliberately
    curl -O http://step.esa.int/downloads/5.0/installers/$SNAP_INSTALLER
    chmod +x $SNAP_INSTALLER
    echo -e "o\n1\n/usr/local/snap\n2\ny\ny\ny\n/usr/bin/python2.7\ny\n" | ./$SNAP_INSTALLER
    #echo -e "o\n1\n\n\n2,3\ny\n\ny\n\ny\n"

    # File system configuration for SNAP' datafiles
    cd $SNAP_LOC/snap/modules/lib/x86_64/
    ln -s ../amd64/libjhdf.so
    ln -s ../amd64/libjhdf5.so
}

install_filebeat() {

# apt-get install -y apt-transport-https
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
# apt-get update
# apt-get install -y filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.4.3-x86_64.rpm
sudo rpm -vi filebeat-5.4.3-x86_64.rpm
}

configure_python_interface() {
# Dump SNAP with fake display port
     export DISPLAY=:1
     Xvfb :1 -screen 0 1024x768x16 &
     XPID=$!
# SNAP update
      snap --nogui --nosplash --modules --refresh --update-all &
      wait $!
# Python interface configuration ! Really unstable when running remotely via SSH !
      snap --nogui --python /usr/bin/python2.7 &
      wait $!
# Kill display port
      kill -15 $XPID
  }

install_S1_toolbox
install_filebeat
#ls ~/.snap/snap-python/snappy/
#configure_python_interface
echo $?
