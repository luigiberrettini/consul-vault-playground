#!/bin/bash

function defineAclPolicy()
{
    printf "***** Defining an ACL policy\n"

    local aclPolicyFileName=secretAclPolicy.hcl
    local aclPolicyHostFilePath=$VAULT_CLIENT_WORK_DIR/$aclPolicyFileName
    local aclPolicyContainerFilePath=/config/$aclPolicyFileName

    printf "path \"secret/hello1\" { policy = \"write\" }\npath \"secret/hello2\" { policy = \"read\" }\n" > $aclPolicyHostFilePath
    printf "Policy:\n$(cat $aclPolicyHostFilePath)\n"
    _vaultClientDefaultToken policy-write secret $aclPolicyContainerFilePath && rm $aclPolicyHostFilePath
}

function _createTokenForTokenAuthBackend()
{
    local aclPolicyName=$1
    local createTokenOutput=''

    if [ -z "$aclPolicyName" ]; then
        _vaultClientDefaultToken token-create 2>&1
    else
        _vaultClientDefaultToken token-create -policy=$aclPolicyName 2>&1
    fi
}

function _extractTokenFromText()
{
    local text=$1
    printf "$text" | grep 'token' | grep -v 'token_' | awk '{ print $2 }'
}

function tokenAuthBackendBasic()
{
    printf "***** Basic token auth backend\n"

    local createTokenOutput=$(_createTokenForTokenAuthBackend)
    local newToken=$(_extractTokenFromText "$createTokenOutput")
    printf "$createTokenOutput\n\n"
    
    _vaultClientDefaultToken auth $newToken
    _vaultClientDefaultToken token-revoke $newToken
}

function tokenAuthBackendWithPolicy()
{
    printf "***** ACL policy token auth backend\n"

    local createTokenOutput=$(_createTokenForTokenAuthBackend secret)
    local newToken=$(_extractTokenFromText "$createTokenOutput")
    printf "$createTokenOutput\n\n"

    _vaultClientDefaultToken auth $newToken
    _vaultClientCustomToken $newToken write secret/hello1 value=newworld
    _vaultClientCustomToken $newToken write secret/hello2 value=updatedworld
    _vaultClientCustomToken $newToken mounts
    _vaultClientDefaultToken token-revoke $newToken
}

function enableGitHubAuthBackend()
{
    printf "***** Enabling GitHub auth backend\n"

    _vaultClientDefaultToken auth-enable github
}

function configureGitHubAuthBackend()
{
    printf "***** Configuring GitHub auth backend\n"

    _vaultClientDefaultToken write auth/github/config organization=CodersTUG
    printf "Configured GitHub backend to only accept users from the CodersTUG organization\n"

    _vaultClientDefaultToken write auth/github/map/teams/default value=root
    printf "Map any team of CodersTUG to the root policy\n"
}

function authenticateToGitHubAuthBackend()
{
    printf "***** Authenticating to GitHub auth backend\n"

    githubToken=$(cat github-token.txt)
    _vaultClientDefaultToken auth -method=github token=$githubToken
}

function revokeTokenForGitHubAuthBackend()
{
    printf "***** Revoking token for GitHub auth backend\n"

    _vaultClientDefaultToken token-revoke -mode=path auth/github
    printf "Needed dev mode Vault server restart or different root token\n"
}

function disableGitHubAuthBackend()
{
    printf "***** Disabling GitHub auth backend\n"

    _vaultClientDefaultToken auth-disable github
    printf "Needed dev mode Vault server restart or different root token\n"
}