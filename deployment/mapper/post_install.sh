#!/bin/bash
set -x
set -e
#
# Functional on Ubuntu distribution Version 16.04 LTS
#

install_S1_toolbox() {

    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME
    PATH=$PATH:$JAVA_HOME/bin

    SNAP_INSTALLER=esa-snap_sentinel_unix_5_0.sh

    curl -O http://step.esa.int/downloads/5.0/installers/$SNAP_INSTALLER
    chmod +x $SNAP_INSTALLER
    echo -e "o\n1\1n\n2\n\n/usr/bin/python2.7\ny\n" | ./$SNAP_INSTALLER
}

  configure_python_interface() {
# Check for the SNAP installation output directory
# b.c. it may defer depending on the cloud service
    SNAP_LOC=/opt/snap
    if [ ! -d $SNAP_LOC ]; then
      SNAP_LOC=/usr/local/snap
    fi
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
# File system configuration
      cd $SNAP_LOC/snap/modules/lib/x86_64/
      ln -s ../amd64/libjhdf.so
      ln -s ../amd64/libjhdf5.so
  }

install_S1_toolbox
ls ./snap/snap-python/snappy/
#configure_python_interface
echo $?
