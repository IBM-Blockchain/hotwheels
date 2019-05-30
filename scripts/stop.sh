#!/bin/sh
BASEDIR=$(dirname "$0")

BASEDIR=$(dirname "$0")

if [ $BASEDIR = '.' ]
then
    BASEDIR=$(pwd)
elif [ ${BASEDIR:0:2} = './' ]
then
    BASEDIR=$(pwd)${BASEDIR:1}
elif [ ${BASEDIR:0:1} = '/' ]
then
    BASEDIR=${BASEDIR}
else
    BASEDIR=$(pwd)/${BASEDIR}
fi

NETWORK_DOCKER_COMPOSE_DIR=$BASEDIR/network/docker-compose
APP_DOCKER_COMPOSE_DIR=$BASEDIR/apps/docker-compose

echo '############################'
echo '# REMOVE DOCKER CONTAINERS #'
echo '############################'
docker-compose -f $NETWORK_DOCKER_COMPOSE_DIR/docker-compose.yaml -p node down --volumes
docker rm -f $(docker ps -a | grep "dev-peer0.arium" | awk '{print $1}')
docker rm -f $(docker ps -a | grep "dev-peer0.vda" | awk '{print $1}')
docker rm -f $(docker ps -a | grep "dev-peer0.prince-insurance" | awk '{print $1}')

echo '#############################'
echo '# REMOVE DEPLOYED CHAINCODE #'
echo '#############################'
docker rmi $(docker images | grep "^dev-peer0.arium" | awk '{print $3}')
docker rmi $(docker images | grep "^dev-peer0.vda" | awk '{print $3}')
docker rmi $(docker images | grep "^dev-peer0.prince-insurance" | awk '{print $3}')

echo '##################'
echo '# CLEANUP CRYPTO #'
echo '##################'
docker-compose -f $NETWORK_DOCKER_COMPOSE_DIR/docker-compose-cli.yaml up -d
docker exec cli bash -c 'cd /etc/hyperledger/config; rm -rf crypto-config; rm -f channel.tx; rm -f core.yaml; rm -f genesis.block; rm -f vehiclemanufacture.block'
docker-compose -f $NETWORK_DOCKER_COMPOSE_DIR/docker-compose-cli.yaml down --volumes

echo '###############'
echo '# CLEANUP TMP #'
echo '###############'
rm -rf $BASEDIR/tmp

echo '################'
echo '# CLEANUP APPS #'
echo '################'
CAR_BUILDER_PORT=6004
ARIUM_PORT=6001
VDA_PORT=6002
PRINCE_PORT=6003

APPS_PATH=$BASEDIR/../apps

rm -rf $APPS_PATH/manufacturer/vehiclemanufacture_fabric/wallet/*/
rm -rf $APPS_PATH/insurer/vehiclemanufacture_fabric/wallet/*/
rm -rf $APPS_PATH/regulator/vehiclemanufacture_fabric/wallet/*/

docker exec arium_app bash -c 'vehiclemanufacture_fabric/wallet/*/'
docker exec vda_app bash -c 'vehiclemanufacture_fabric/wallet/*/'
docker exec prince_app bash -c 'vehiclemanufacture_fabric/wallet/*/'

docker-compose -f $APP_DOCKER_COMPOSE_DIR/docker-compose.yaml -p node down --volumes

for PORT in $CAR_BUILDER_PORT $ARIUM_PORT $VDA_PORT $PRINCE_PORT
do
    lsof -i :$PORT | awk '{if(NR>1)print $2}' | xargs kill
done

echo "#################"
echo "# STOP COMPLETE #"
echo "#################"