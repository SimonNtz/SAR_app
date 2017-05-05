#!/bin/bash

#
# For Ubuntu distribution Version 16.04 LTS
#

set -e
set -x
set -o pipefail


gh=https://raw.githubusercontent.com
branch=master

#set up to display products on remote ssh machine through X11
#echo -e "ForwardX11 yes\nForwardX11Trusted yes\n" >> /etc/ssh/ssh_config
#export DISPLAY=:0.0

workspace=/home/data
mkdir -p $workspace
cd $workspace
echo 'TEST'
id=`ss-get id`
# full list of product
SAR_data=(`ss-get product_url`)
my_product=${SAR_data[$id-1]}
# this mapper product
#my_product=${SAR_data[5]}



get_data() {
    curl -o sarget.sh -sSfL $gh/SimonNtz/SAR_app/$branch/sarget.sh
    echo $(date)
    bash sarget.sh -d 'https://dhr1.cesnet.cz' -u SimonNtz -p mario1992 -F $my_product -o product -O /home/data -n 15
    echo $(date)
    unzip *.zip
}

run_proc() {
   curl -o SAR_test_proc.py -sSfL $gh/SimonNtz/SAR_app/$branch/SAR_test_proc.py
   echo "java_max_mem: 14G" >> /home/snap-engine/snap-python/src/main/resources/snappy/snappy/snappy.ini
   #TODO check if SAR_data is not empty!
   python SAR_test_proc.py $my_product
   #TODO clear .snap/var/temp/cache files
   find /home/data/ -maxdepth 1 -name *.png -exec cp {} $id.png \;
}

deploy_nginx() {
apt-get -y install nginx

# remove default site and create our own
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-enabled/mysite <<EOF
server {
  listen 80 default_server;

  root /home/data;
  index index.html;
}
EOF

update-rc.d nginx enable
service nginx start
service nginx restart
}


# provide a link to the webserver through slipstream
hostname=`ss-get hostname`
link=http://${hostname}/
ss-set ss:url.service ${link}

get_data
echo $date
run_proc
echo $date
deploy_nginx

ss-set ready true

# provide status information through web UI
ss-display "Webserver ready on ${link}!"
