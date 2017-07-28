#!/bin/bash
set -e
set -x
set -o pipefail

source ../lib.sh
id=`ss-get id`
SAR_data=(`ss-get product-list`)
[ -n "$SAR_data" ] || ss-abort -- "product-list should not be empty."

my_product=${SAR_data[$id-1]}
IFS=' ' read -r -a my_product <<< "$my_product"

S3_HOST=`ss-get s3-host`
S3_BUCKET=`ss-get s3-bucket`

reducer_ip=`ss-get reducer:hostname`

get_data() {
    echo "@MAPPER_RUN - "$(timestamp) " - start downloading"
    bucket=${1?"Provide bucket name."}
    echo $(date)
    for i in ${my_product[@]}; do
        python3  get_data.py "https://$S3_HOST/$S3_BUCKET/" "$i.SAFE"
        echo "@MAPPER_RUN - "$(timestamp) " - finish downloading - \
        $i.SAFE - `get_file_size $i.SAFE`"
        #sudo s3cmd get --recursive s3://$bucket/$i.SAFE
    done

}

# start_filebeat() {
#
# #server_ip=`ss-get --timeout=300 ELK_server:hostname`
# #server_hostname=`ss-get --timeout=300 ELK_server:machine-hn`
# server_hostname=`ss-get --timeout=300 server_hn`
# server_ip=`ss-get --timeout=300 server_ip`
#
# echo  "$server_ip   $server_hostname">>/etc/hosts
#
# cd /etc/filebeat/
#
# filebeat_conf=filebeat.yml
#
# #Set Logstash as an input instead of ElasticStash
# sed -i '81,83 s/^/#/' $filebeat_conf
# # awk '{ if (NR == 22) print "    - /var/log/auth.log\n    - /var/log/syslog\n \
# #     - /var/log/slipstream/client/slipstream-node.log";else print $0}' \
# #         $filebeat_conf > tmp && mv tmp $filebeat_conf
#
# cat>$filebeat_conf<<EOF
# filebeat.prospectors:
# - input_type: log
#
#   paths:
#     - /var/log/auth.log
#     - /var/log/syslog
#     - /var/log/slipstream/client/slipstream-node.log
#
# output.logstash:
#   # The Logstash hosts
#   hosts: ["$server_hostname:5443"]
#   bulk_max_size: 2048
#   template.name: "filebeat"
#   template.path: "filebeat.template.json"
#   template.overwrite: false
# document-type: syslog
# EOF
#
# chmod go-w $filebeat_conf
# filebeat.sh -configtest -c $filebeat_conf
#
# sudo systemctl start filebeat
# sudo systemctl enable filebeat
#
# # Capture filebeat status
# systemctl status filebeat | grep Active
# }

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

#config_s3 $S3_HOST $S3_ACCESS_KEY $S3_SECRET_KEY

start_filebeat
echo "@MAPPER_RUN - "$(timestamp)" - start deployment"
cd ~/SAR_app/deployment/mapper
get_data $S3_BUCKET $S3_HOST
run_proc
push_product
echo "@MAPPER_RUN - "$(timestamp)" - finish deployment"
ss-set ready true
