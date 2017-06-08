#!/bin/bash
set -x
set -e
#
# Functional on Ubuntu distribution Version 16.04 LTS
#
s
install_S1_toolbox() {

    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME
    PATH=$PATH:$JAVA_HOME/bin

    SNAP_INSTALLER=esa-snap_sentinel_unix_5_0.sh

    curl -O http://step.esa.int/downloads/5.0/installers/$SNAP_INSTALLER
    chmod +x $SNAP_INSTALLER
    echo -e "o\n1\n\n\n2,3\ny\n\ny\n\ny\n" | ./$SNAP_INSTALLER
}

  configure_python_interface() {

      export DISPLAY=:1
      Xvfb :1 -screen 0 1024x768x16 &
      XPID=$!

      SNAP_LOC=`which snap`

      $SNAP_LOC/snap --nosplash --python /usr/bin/python2.7 &
      #sleep 5
      kill -15 $XPID
      cd $SNAP_LOC/snap/modules/lib/x86_64/
      ln -s ../amd64/libjhdf.so
      ln -s ../amd64/libjhdf5.so
  }

install_S1_toolbox
configure_python_interface
echo $?
