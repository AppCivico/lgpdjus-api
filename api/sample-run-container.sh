#!/bin/bash -e

# Arquivo de exemplo para iniciar o container
export SOURCE_DIR="$HOME/projects/v2lgpdjus/api"
export DATA_DIR='/not-tmp/v2lgpdjus/data/'

mkdir -p $DATA_DIR

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Directory '$SOURCE_DIR' does not exists";
    exit 1;
fi

# Confira o seu ip usando ifconfig docker0|grep 'inet addr:'
export DOCKER_LAN_IP=172.17.0.1

# Porta que será feito o bind
export LISTEN_PORT=8080

docker run --name its_lgpdjus_api \
 -v $SOURCE_DIR:/src -v $DATA_DIR:/data \
 -p $DOCKER_LAN_IP:$LISTEN_PORT:8080 \
 --cpu-shares=512 \
 --memory 1800m -d --restart unless-stopped its/lgpdjus_api
