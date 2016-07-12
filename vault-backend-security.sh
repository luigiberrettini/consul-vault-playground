#!/bin/bash

function defineAclPolicy()
{
    printf "path \"secret/hello1\" { policy = \"write\" }\npath \"secret/hello2\" { policy = \"read\" }\n" > secretAclPolicy.hcl
    _vaultClientDefaultToken policy-write secret secretAclPolicy.hcl
}

function _createTokenForTokenAuthBackend()
{
    local aclPolicyName=$1
    local createTokenOutput=''

    if [ -z "$aclPolicyName" ]; then
        createTokenOutput=$(_vaultClientDefaultToken token-create -policy=$aclPolicyName 2>&1)
    else
        createTokenOutput=$(_vaultClientDefaultToken token-create 2>&1)
    fi
    printf "$createTokenOutput\n"
    
    printf "$createTokenOutput\n" | tail -n +2 | head | awk '{ print $2 }'
}

function tokenAuthBackendBasic()
{
    local newToken=$(_createTokenForTokenAuthBackend)
    _vaultClientDefaultToken auth $newToken
    _vaultClientDefaultToken token-revoke $newToken
}

function tokenAuthBackendWithPolicy()
{
    local newToken=$(_createTokenForTokenAuthBackend secret)
    _vaultClientDefaultToken auth 
    _vaultClientCustomToken $newToken write secret/hello1 value=newworld
    _vaultClientCustomToken $newToken write secret/hello2 value=updatedworld
    _vaultClientCustomToken $newToken mounts
    _vaultClientDefaultToken token-revoke $newToken
}

function enableGitHubAuthBackend()
{
    _vaultClientDefaultToken auth-enable github
}

function configureGitHubAuthBackend()
{
    _vaultClientDefaultToken write auth/github/config organization=CodersTUG
    printf "Configured GitHub backend to only accept users from the CodersTUG organization\n"

    _vaultClientDefaultToken write auth/github/map/teams/default value=root
    printf "Map any team to the of CodersTUG to the root policy\n"
}

function authenticateToGitHubAuthBackend()
{
    githubToken=$(cat github-token.txt)
    _vaultClientDefaultToken auth -method=github token=$githubToken
}

function revokeTokenToGitHubAuthBackend()
{
    _vaultClientDefaultToken token-revoke -mode=path auth/github
    printf "Needed dev mode Vault server restart or different root token\n"
}

function disableGitHubAuthBackend()
{
    _vaultClientDefaultToken auth-disable github
    printf "Needed dev mode Vault server restart or different root token\n"
}