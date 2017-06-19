#!/bin/bash
set -e
set -x
set -o pipefail

SAR_data=(`ss-get product-list`)
[ -n "$SAR_data" ] || ss-abort -- "product-list should not be empty."

source ../lib.sh

id=`ss-get id`
my_product=${SAR_data[$id-1]}
IFS=' ' read -r -a my_product <<< "$my_product"
echo "Product for processing: ${my_product[@]}"

S3_HOST=`ss-get s3-host`
S3_BUCKET=`ss-get s3-bucket`
S3_ACCESS_KEY=`ss-get s3-access-key`
S3_SECRET_KEY=`ss-get s3-secret-key`

reducer_ip=`ss-get reducer:hostname`

get_data() {
    bucket=${1?"Provide bucket name."}
    echo $(date)
    for i in ${my_product[@]}; do
        sudo s3cmd get --recursive s3://$bucket/$i.SAFE
    done
    echo $(date)
}

run_proc() {
    echo "java_max_mem: `ss-get snap_max_mem`" >> /root/.snap/snap-python/snappy/snappy.ini
    SAR_proc=~/SAR_proc/SAR_mapper.py

    for i in ${my_product[@]}; do
        python $SAR_proc $i
    done

    # FIXME SAR_proc should store into current directory.
    find . -maxdepth 1 -name *.png -exec cp {} $id.png \;
    #TODO clear .snap/var/temp/cache files
}

push_product() {
    nc $reducer_ip 808$id < $id.png
}

config_s3 $S3_HOST $S3_ACCESS_KEY $S3_SECRET_KEY
get_data $S3_BUCKET
run_proc
push_product

ss-set ready true
