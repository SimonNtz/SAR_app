#!/bin/bash
set -e
set -x
set -o pipefail

#
# For Ubuntu distribution Version 16.04 LTS
#

SAR_data=(`ss-get product_list`)
[ -n "$SAR_data" ] || ss-abort -- "product-list should not be empty."

source 

workspace=/home/data
mkdir -p $workspace
cd $workspace
id=`ss-get id`
my_product=${SAR_data[$id-1]}
IFS=' ' read -r -a my_product <<< "$my_product"
echo "Product for processing: ${my_product[@]}"

S3_HOST=`ss-get s3-host`
S3_BUCKET=`ss-get s3-bucket`
S3_ACCESS_KEY=`ss-get s3-access-key`
S3_SECRET_KEY=`ss-get s3-secret-key`


get_data() {
    bucket=$1
    echo $(date)
    for i in ${my_product[@]}; do
        sudo s3cmd get --recursive s3://$bucket/$i.SAFE
    done
    echo $(date)
}

run_proc() {
    get_file_github app/SAR_proc.py
    echo "java_max_mem: 14G" >> /home/snap-engine/snap-python/src/main/resources/snappy/snappy/snappy.ini
    for i in ${my_product[@]}; do
           python SAR_proc.py $i
    done
    find /home/data/ -maxdepth 1 -name *.png -exec cp {} $id.png \;
    #TODO clear .snap/var/temp/cache files
}

push_product() {
    nc $reducer_ip 808$id < $id.png
}

# Retrieve the client's Nuvla token through the application component parameters

reducer_ip=`ss-get reducer:hostname`
create_cookie "`ss-get --noblock reducer:nuvla_token`"
config_s3 $S3_HOST $S3_ACCESS_KEY $S3_SECRET_KEY
install_slipstream_api
post_event "mapper.$id: starts downloading $my_product"
get_data $S3_BUCKET
post_event "mapper.$id: starts image processing"
run_proc
post_event "mapper.$id: is sending output to reducer"
push_product
ss-set ready true
