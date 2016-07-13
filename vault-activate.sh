#!/bin/bash

declare -A VAULT_ROOT_TOKENS
declare -A VAULT_UNSEAL_KEY_SETS

function _setVaultRootTokenAndUnsealKeySet()
{
    local hashmapKey=$1
    local text=$2

    VAULT_ROOT_TOKENS[$hashmapKey]=$(printf "$text" | grep 'Root Token' | awk '{ print $(NF), $NF }')
    VAULT_UNSEAL_KEY_SETS[$hashmapKey]=$(printf "$text" | grep 'Unseal Key' | awk '{ print $(NF), $NF }')
}

function showVaultRootTokenAndUnsealKeySet()
{
    local hashmapKey=$1
    printf "Root token: ${VAULT_ROOT_TOKENS[$hashmapKey]}\n\n"
    printf "Unseal key set: ${VAULT_UNSEAL_KEY_SETS[$hashmapKey]}\n\n"
}

function startVaultServerDev()
{
    printf "***** Starting a Vault Server in dev mode\n"

    local containerName='vaultdi'
    docker run -p 8211:8200 --name $containerName -h $containerName -d sjourdan/vault
    sleep 2
    _printLogs $containerName
    _setVaultRootTokenAndUnsealKeySet $containerName "$(_printLogs $containerName)"
}

function startVaultServerStdFileStorageBackend()
{
    printf "***** Starting a Vault Server in standard mode using file storage backend\n"

    local configFolder=$1
    local containerName='vaultsf'

    docker run -v $configFolder:/config -p 8221:8200 --name $containerName -h $containerName -d sjourdan/vault server -config=/config/file.hcl
    sleep 2
    _printLogs $containerName
}

function startVaultServerStdConsulStorageBackend()
{
    printf "***** Starting a Vault Server in standard mode using Consul storage backend\n"

    local consulContainerName=$1
    local configFolder=$2
    local containerName='vaultsc'

    docker run --link $consulContainerName:consul -v $configFolder:/config -p 8231:8200 --name $containerName -h $containerName -d sjourdan/vault server -config=/config/consul.hcl
    sleep 2
    _printLogs $containerName
}

#curl --fail http://<vault server>/v1/sys/health || exit 2

function _vaultClientCustomServerAndToken()
{
    local vaultServerContainerName=$1
    local tokenMode=$2
    local authToken=$3

    shift
    if [ -z "$vaultServerContainerName" ]; then
        vaultServerContainerName=$VAULT_SERVER_CONTAINER_NAME
        if [ -z "$vaultServerContainerName" ]; then
            vaultServerContainerName='vaultdi'
        fi
    fi

    local vaultIp="$(_containerIp $vaultServerContainerName)"

    local vaultAddr="http://$vaultIp:8200"

    shift
    local vaultCommand="vault $*"
    if [ "$tokenMode" == "token" ]; then
        shift
        if [ -z "$authToken" ]; then
            authToken=$AUTH_TOKEN
            if [ -z "$authToken" ]; then
                authToken=${VAULT_ROOT_TOKENS[$vaultServerContainerName]}
            fi
        fi
        vaultCommand="vault auth $authToken &>/dev/null; vault $*"
    fi
    
    docker run -it --rm -e "VAULT_ADDR=$vaultAddr" --entrypoint=/bin/sh sjourdan/vault -c "$vaultCommand"
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

function initVaultFromCli()
{
    printf "***** Initializing Vault\n"

    local initOutput=$(_vaultClientNoToken init)
    _setVaultRootTokenAndUnsealKeySet $VAULT_SERVER_CONTAINER_NAME "$initOutput"
}

function unsealVault()
{
    printf "***** Unsealing Vault\n"

    local key=$1
    _vaultClientNoToken unseal $key
}