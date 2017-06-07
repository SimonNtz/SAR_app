#!/bin/bash
set -x
set -e

#
# For Ubuntu distribution Version 16.04 LTS
#

INSTAL4J_LICENSE_KEY=${1?"Provide Install4j license key."}

source ../lib.sh



install_S1_toolbox() {

    # MAVEN_HOME=/usr/bin/mvn
    # export MAVEN_HOME
      #PATH=$PATH:$MAVEN_HOME/bin
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME
    PATH=$PATH:$JAVA_HOME/bin
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
#echo -e "ForwardX11 yes\nForwardX11Trusted yes\n" >> /etc/ssh/ssh_config
#export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
}

  configure_python_interface() {
      Xvfb :1 -screen 0 1024x768x16 &
      XPID=$!
      export DISPLAY=:1
      #TODO: check if SNAP is correctly installed
      snaploc=/usr/local
      $snaploc/bin/snap --nosplash --python /usr/bin/python2.7 &
      sleep 5
      kill -15 $XPID
      # $snaploc/bin/snap --nogui --nosplash --python /usr/bin/python2.7
      cd $snaploc/snap/snap/modules/lib/x86_64/
      ln -s ../amd64/libjhdf.so
      ln -s ../amd64/libjhdf5.so
  }


install_S1_toolbox
configure_python_interface
echo $?
#install_slipstream_api
