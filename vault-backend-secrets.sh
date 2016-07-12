#!/bin/bash

function writeSecretAndReadAsText()
{
    _vaultClientDefaultServerAndToken write secret/hello1 value=world
    _vaultClientDefaultServerAndToken read secret/hello1
}

function writeSecretAndReadAsJson()
{
    _vaultClientDefaultServerAndToken write secret/hello2 value=world excited=yes
    _vaultClientDefaultServerAndToken read -format=json secret/hello2 | jq
}

function deleteSecret()
{
    _vaultClientDefaultServerAndToken write secret/hello3 value=world3
    _vaultClientDefaultServerAndToken delete secret/hello3
    _vaultClientDefaultServerAndToken write secret/hello3 value=world3
}

function showMountPointsForSecretBackends()
{
    _vaultClientDefaultServerAndToken mounts
}

function showMountPointsIsolation()
{
    _vaultClientDefaultServerAndToken mount generic
    _vaultClientDefaultServerAndToken write generic/hallo value=foobar
    _vaultClientDefaultServerAndToken read secret/hallo
    _vaultClientDefaultServerAndToken unmount generic
}
