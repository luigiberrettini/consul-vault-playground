#!/bin/bash

export DOCKER_HOST=tcp://0.0.0.0:2375

function cloneDockerConsulTemplate()
{
    printf "***** Cloning Docker consul-template repo\n"

    git clone http://github.com/luigiberrettini/docker-consul-template

    printf "Building consultmpl8 image\n"
    cd docker-consul-template && docker build -t consultmpl8 . && cd ..
}

function startTemplateRenderer()
{
    printf "***** Starting consul-template continuous rendering\n"

    local containerName=$1
    local templateFolder=$2
    local templateName=$3
    local outputName=$3

    printf "Destroying previous consultmpl8 containers\n"
    local toBeDestroyed=$(docker ps -a | tail -n +2 | grep consultmpl8 | awk '{ print $1 }')
    docker stop $toBeDestroyed > /dev/null 2>&1
    docker rm $toBeDestroyed > /dev/null 2>&1

    printf "Running consultmpl8 to render $templateName to $outputName\n"
    docker run --link $containerName:consul -v $templateFolder:/work -d consultmpl8 consul-template -consul consul:8500 -template "/work/$templateName:/work/$outputName"
    cat /work/$templateName
    cat /work/$outputName
}
