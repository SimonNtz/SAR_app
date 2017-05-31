#!/bin/bash

set -e
set -x

source ../lib.sh
echo '-----------------'
whoami
pwd
echo '-----------------'
install_slipstream_api
