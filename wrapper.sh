#!/bin/bash

export DOCKER_HOST=tcp://0.0.0.0:2375
export VAULT_SERVER_CONTAINER_NAME=vaultd
#export VAULT_SERVER_CONTAINER_NAME=vaultsd
#export VAULT_SERVER_CONTAINER_NAME=vaultso

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

source ./consul-standard.sh
source ./consul-template.sh

source ./vault-activate.sh
source ./vault-backend-secrets.sh
source ./vault-backend-security.sh
source ./vault-http-api.sh