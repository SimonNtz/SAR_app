#!/env/bin bash

#pip install slipstream-client
#pip install slipstream-cli

export SLIPSTREAM_USERNAME=simon1992
export SLIPSTREAM_PASSWORD=12mc0v2ee64o9

#for a system-level installation. If you don’t have administrator access to your machine,

#you can also perform a user-level installation:

#pip install --user slipstream-client

alias ss-curl="curl --cookie-jar ~/cookies -b ~/cookies -sS"

ss-curl https://nuv.la/auth/login \
    -D - \
    -o /dev/null \
    -XPOST \
    -d "username=$SLIPSTREAM_USERNAME" \
    -d "password=$SLIPSTREAM_PASSWORD"

ss-get-user ss-get-user
#ss-execute --parameters="mapper:multiplicity=3","mapper:cloudservice=eo-cesnet-cz1","reducer:cloudservice=eo-cesnet-cz1" EO_Sentinel_1/procSAR
