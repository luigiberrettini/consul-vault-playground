#!/bin/bash

export DOCKER_HOST=tcp://0.0.0.0:2375
export VAULT_SERVER_CONTAINER_NAME='vaultdi'
#export VAULT_SERVER_CONTAINER_NAME='vaultsf'
#export VAULT_SERVER_CONTAINER_NAME='vaultsc'
export VAULT_CLIENT_WORK_DIR=$(pwd)/../vault-client-work-dir

function destroyContainers()
{
    printf "***** Destroying containers\n"

    local imageNameFilter=$1

    printf "List of all containers before destruction\n"
    docker ps -a

    printf "Stopping and removing containers\n"
    local toBeDestroyed=$(docker ps -a | tail -n +2 | grep $imageNameFilter | awk '{ print $1 }')
    docker stop $toBeDestroyed > /dev/null
    docker rm $toBeDestroyed > /dev/null

    printf "List of all containers after destruction\n"
    docker ps -a
}

function _interfaceIp()
{
    local interfaceName=$1
    ifconfig $interfaceName | grep inet | head -n 1 | awk '{print $2}'
}

function _dockerBridgeIp()
{
    _interfaceIp docker0
}

function _usedInterfaceIp()
{
    local interfaceName=$(ifconfig -a | grep $(netstat -i | tail -n +3 | awk '{print $1}' | grep -vE 'docker0|lo|veth') | sed 's@:.*@@')
    _interfaceIp $interfaceName
}

function _containerIp()
{
    local containerName=$1
    docker inspect -f '{{.NetworkSettings.IPAddress}}' $containerName
}

function _printContainerNameAndIp()
{
    local containerName=$1
    printf "$containerName IP: $(_containerIp $containerName)\n\n"
}

function _printLogs()
{
    local containerName=$1
    docker logs $containerName 2>&1
}

source ./consul-standard.sh
source ./consul-template.sh

source ./vault-activate.sh
source ./vault-backend-secrets.sh
source ./vault-backend-security.sh
source ./vault-http-api.sh