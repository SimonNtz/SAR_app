#!/bin/bash

#
# For Ubuntu distribution Version 16.04 LTS
#

set -e
set -x
set -o pipefail


apt-get install -y python-numpy
apt-get install -y python-matplotlib
apt-get install -y python-scipy
apt-get install -y imagemagick

echo "java_max_mem: 14G" >> /home/snap-engine/snap-python/src/main/resources/snappy/snappy/snappy.ini
echo -e "ForwardX11 yes\nForwardX11Trusted yes\n" >> /etc/ssh/ssh_config
export DISPLAY=:0.0

cd /home
mkdir -p data

gh=https://raw.githubusercontent.com
branch=master

cd data

curl -o getSAR_data.sh -sSfL $gh/SimonNtz/SAR_app/$branch/getSAR_data.sh
curl -o SAR_test_proc.py -sSfL $gh/SimonNtz/SAR_app/$branch/SAR_test_proc.py

chmod +x getSAR_data.sh
bash getSAR_data.sh
unzip *.zip

SAR_data="S1A_IW_GRDH_1SDV_20151226T182813_20151226T182838_009217_00D48F_5D5F,S1A_IW_GRDH_1SDV_20160424T182813_20160424T182838_010967_010769_AA98,S1A_IW_GRDH_1SDV_20160518T182817_20160518T182842_011317_011291_936E,S1A_IW_GRDH_1SDV_20160611T182819_20160611T182844_011667_011DC0_391B,S1A_IW_GRDH_1SDV_20160705T182820_20160705T182845_012017_0128E1_D4EE,S1A_IW_GRDH_1SDV_20160729T182822_20160729T182847_012367_013456_E8BF,S1A_IW_GRDH_1SDV_20160822T182823_20160822T182848_012717_013FFE_90AF,S1A_IW_GRDH_1SDV_20160915T182824_20160915T182849_013067_014B77_1FCD"

python SAR_test_proc.py  $SAR_data

#TODO clear .snap/var/temp/cache files
convert -delay 20 -loop 0 *.png SAR_animation.gif
