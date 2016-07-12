#!/bin/bash

function writeSecretAndReadAsText()
{
    printf "***** Writing secrets and reading as text\n"

    _vaultClientDefaultToken write secret/hello1 value=world
    _vaultClientDefaultToken read secret/hello1
}

function writeSecretAndReadAsJson()
{
    printf "***** Writing secrets and reading as JSON\n"

    _vaultClientDefaultToken write secret/hello2 value=world excited=yes
    _vaultClientDefaultToken read -format=json secret/hello2 | jq
}

function deleteSecret()
{
    printf "***** Writing secrets, deleting them and writing them again\n"

    _vaultClientDefaultToken write secret/hello3 value=world3
    _vaultClientDefaultToken delete secret/hello3
    _vaultClientDefaultToken write secret/hello3 value=world3
}

function showMountPointsForSecretBackends()
{
    printf "***** Showing mount points for secret backends\n"

    _vaultClientDefaultToken mounts
}

function showMountPointsIsolation()
{
    printf "***** Showing mount points isolation\n"

    _vaultClientDefaultToken mount generic
    _vaultClientDefaultToken write generic/hallo value=foobar
    _vaultClientDefaultToken read secret/hallo
    _vaultClientDefaultToken unmount generic
}
