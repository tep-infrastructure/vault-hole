#!/bin/bash

set -e

IMAGE_NAME="hashicorp/vault:1.12"

docker image pull $IMAGE_NAME 

docker rename vault vault_backup
docker stop vault_backup

docker run --name vault \
   -d \
   -v $PWD/vault:/vault/config \
   -v $PWD/vault-file:/vault/file \
   --cap-add=IPC_LOCK \
   -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
   --restart unless-stopped \
   --network vault-hole-network \
   $IMAGE_NAME server

echo "Update completed. It may take a few minutes for Vault to restart."
echo "The old vault is now called vault_backup and can be restored manually."

