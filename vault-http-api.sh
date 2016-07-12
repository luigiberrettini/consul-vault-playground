#!/bin/bash

function checkInitStatus()
{
    # 8220
    local port=$1
    curl --silent "http://127.0.0.1:$port/v1/sys/init" | jq
}

function initVault()
{
    local port=$1
    curl --silent -X PUT --data '{"secret_shares": 1, "secret_threshold": 1}' 'http://localhost:$port/v1/sys/init' | jq
}