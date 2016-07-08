#!/bin/bash

function vaultServerDev()
{
    docker run -p 8200:8200 --name vault -h vault -d sjourdan/vault
}

function vaultServerStdDemoConsul()
{
    local configFolder=$1

    docker run -p 8200:8200 --name vault -h vault -d sjourdan/vault
    docker run -v $configFolder:/config -p 8200:8200 --name vault -h vault -d sjourdan/vault server -config=/config/demo.hcl
}

function vaultServerStdOwnConsul()
{
    local containerName=$1
    local configFolder=$2

    docker run --link $containerName:consul -v $configFolder:/config -p 8200:8200 --name vault -h vault -d sjourdan/vault server -config=/config/consul.hcl
}

function exportVaultRootToken()
{
    export VAULT_ROOT_TOKEN=$(docker logs vault 2>&1 | grep 'Root Token' | awk '{ print $3}')
}

function vaultClient ()
{
    local vaultIp="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' vault)"
    local vaultAddr="http://$vaultIp:8200"

    docker run -it --rm -e vaultAddr --entrypoint=/bin/sh sjourdan/vault -c "vault auth $VAULT_ROOT_TOKEN &>/dev/null; vault $*"
}

function writeSecret()
{
    vaultClient write secret/hello value=world
}