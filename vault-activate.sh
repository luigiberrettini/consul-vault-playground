#!/bin/bash

declare -A VAULT_ROOT_TOKENS

function _vaultRootToken()
{
    local vaultServerContainerName=$1
    printf "$(_printLogs $vaultServerContainerName)" | grep 'Root Token' | awk '{ print $3}'
}

function startVaultServerDev()
{
    printf "***** Starting a Vault Server in dev mode\n"

    local containerName='vaultdi'
    docker run -p 8211:8200 --name $containerName -h $containerName -d sjourdan/vault
    sleep 2
    _printLogs $containerName
    VAULT_ROOT_TOKENS[$containerName]=$(_vaultRootToken $containerName)
}

function startVaultServerStdFileStorageBackend()
{
    printf "***** Starting a Vault Server in standard mode using file storage backend\n"

    local configFolder=$1
    local containerName='vaultsf'

    docker run -v $configFolder:/config -p 8221:8200 --name $containerName -h $containerName -d sjourdan/vault server -config=/config/file.hcl
    sleep 2
    _printLogs $containerName
    VAULT_ROOT_TOKENS[$containerName]=$(_vaultRootToken $containerName)
}

function startVaultServerStdConsulStorageBackend()
{
    printf "***** Starting a Vault Server in standard mode using Consul storage backend\n"

    local containerName=$1
    local configFolder=$2
    local containerName='vaultsc'

    docker run --link $containerName:consul -v $configFolder:/config -p 8231:8200 --name $containerName -h $containerName -d sjourdan/vault server -config=/config/consul.hcl
    sleep 2
    _printLogs $containerName
    VAULT_ROOT_TOKENS[$containerName]=$(_vaultRootToken $containerName)
}

#curl --fail http://<vault server>/v1/sys/health || exit 2

function _vaultClientCustomServerAndToken()
{
    local vaultServerContainerName=$1
    local tokenMode=$2
    local authToken=$3

    if [ -z "$vaultServerContainerName" ]; then
        vaultServerContainerName=$VAULT_SERVER_CONTAINER_NAME
        if [ -z "$vaultServerContainerName" ]; then
            vaultServerContainerName='vaultdi'
        fi
    else
        shift
    fi

    local vaultIp="$(_containerIp $vaultServerContainerName)"

    local vaultAddr="http://$vaultIp:8200"

    local vaultCommand="vault $*"
    if [ "$tokenMode" == "token" ]; then
        if [ -z "$authToken" ]; then
            authToken=$AUTH_TOKEN
            if [ -z "$authToken" ]; then
                authToken=${VAULT_ROOT_TOKENS[$vaultServerContainerName]}
            fi
        else
            shift
        fi
        vaultCommand="vault auth $authToken &>/dev/null; vault $*"
    fi
    
    docker run -it --rm -e "VAULT_ADDR=$vaultAddr" --entrypoint=/bin/sh sjourdan/vault -c $vaultCommand
}

function _vaultClientNoToken()
{
    _vaultClientCustomServerAndToken '' notoken $*
}

function _vaultClientDefaultToken()
{
    _vaultClientCustomServerAndToken '' token '' $*
}

function _vaultClientCustomToken()
{
    _vaultClientCustomServerAndToken '' token $*
}

function initVault()
{
    printf "***** Initializing Vault\n"

    _vaultClientNoToken init
}

function unsealVault()
{
    printf "***** Unsealing Vault\n"

    local key=$1
    _vaultClientNoToken unseal $key
}