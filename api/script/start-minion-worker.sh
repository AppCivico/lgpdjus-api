#!/bin/bash -e
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc;
export LGPDJUS_API_LOG_DIR=/data/log/

if [ -f envfile_local.sh ]; then
    source envfile_local.sh
else
    source envfile.sh
fi

export SQITCH_DEPLOY=${SQITCH_DEPLOY:=docker}

# espera pelo cpanm + sqitch da API
sleep 15;

LIBEV_FLAGS=4 APP_NAME=MINION perl /src/script/lgpdjus-api minion worker
