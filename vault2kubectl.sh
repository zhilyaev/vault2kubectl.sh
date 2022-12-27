#!/bin/bash

VAULT_ADDR="https://vault.local"
VAULT_PATH="secret/kubectl"
cluster=$1


if [[ -z "$cluster" ]]; then
  echo "error: cluster did not defined"
  echo "use next command:"
  echo "$ ./$(basename "$0") <cluster>"
  exit 1
fi

if [ "$DEBUG" == "1" ]; then
  env | grep VAULT
  vault kv list -format=yaml $VAULT_PATH | grep $cluster
fi


# DATA
data=$(vault kv get -format=json "$VAULT_PATH/$cluster" | jq '.data.data')
certificate_authority=$( echo $data | jq '.certificate_authority' | base64)
client_certificate=$( echo $data | jq '.client_certificate' | base64)
client_key=$( echo $data | jq '.client_key' | base64)
server=$( echo $data | jq '.server')


# SETUP
kubectl config set-cluster "$cluster" --server="$server"
kubectl config set "clusters.$cluster.certificate-authority-data" "$certificate_authority"
kubectl config set "users.kubernetes-admin@$cluster.client-certificate-data" "$client_certificate"
kubectl config set "users.kubernetes-admin@$cluster.client-key-data" "$client_key"
