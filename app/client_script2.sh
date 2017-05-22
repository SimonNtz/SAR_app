#!/env/bin bash

#TODO verify SS-client install

#Recover token in cookies-nuvla.txt
slipstream login -u $SLIPSTREAM_USERNAME -p $SLIPSTREAM_PASSWORD

NUVLA_TOKEN=`cat ~/.slipstream/cookies-nuvla.txt | grep -v \#`


INPUT_SIZE=`cat product_list.cfg | wc -l`
INPUT_LIST=`cat product_list.cfg`

ss-execute --parameters="mapper:multiplicity=$INPUT_SIZE","mapper:product_url='$INPUT_LIST'","mapper:cloudservice=eo-cesnet-cz1","reducer:cloudservice=eo-cesnet-cz1","reducer:nuvla_token='$NUVLA_TOKEN'" --keep-running="always" EO_Sentinel_1/procSAR
#ss-execute --parameters="mapper:multiplicity=3","mapper:product_url='$INPUT_LIST'","mapper:cloudservice=eo-cesnet-cz1","reducer:cloudservice=eo-cesnet-cz1" EO_Sentinel_1/procSAR
