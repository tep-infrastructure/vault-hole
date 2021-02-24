# Pi Vault

PiHole and Vault, together as one.

## Useful Vault Commands

export VAULT_TOKEN="token_here"
export VAULT_ADDR="http://vault.test.internal"

vault kv list secret/
vault kv put secret/foo password=value
