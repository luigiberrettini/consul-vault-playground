#!/bin/bash

function startVaultServerForApi()
{
    printf "***** Starting a Vault Server in standard mode using file storage backend\n"

    local configFolder=$1
    local containerName='vaultapi'

    docker run -v $configFolder:/config -p 8241:8200 --name $containerName -h $containerName -d sjourdan/vault server -config=/config/file.hcl
    sleep 2
    _printLogs $containerName
}

function checkInitStatus()
{
    printf "***** [HTTP-API] Checking Vault server init status\n"

    # 8241
    local port=$1
    curl --silent "http://127.0.0.1:$port/v1/sys/init" | jq
}

function initVaultFromApi()
{
    printf "***** [HTTP-API] Initializing Vault server\n"

    local port=$1
    local initOutput=$(curl --silent -X PUT --data '{"secret_shares": 5, "secret_threshold": 3}' "http://localhost:$port/v1/sys/init")
    echo -e "$initOutput" | jq
    _setVaultRootTokenAndUnsealKeySet $VAULT_SERVER_CONTAINER_NAME "$initOutput" 'jsonText'
}
