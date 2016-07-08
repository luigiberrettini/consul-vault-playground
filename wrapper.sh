#!/bin/bash

export DOCKER_HOST=tcp://0.0.0.0:2375

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

source ./basic-features.sh
source ./consul-template.sh