# Vault Hole

[PiHole](https://pi-hole.net/) and [Vault](https://www.vaultproject.io/), together as one.

This project aims to host Pihole and Vault together on one device behind an Nginx reverse proxy. All 3 components are in Docker containers.

`init.sh` does a few things:

* Adds the Docker and Hashicorp repos.
* Installs Docker and other needed utilities.
* Installs Vault CLI (Vault CLI isn't directly used, but is useful for admin).
* Generates some self signed certificates.
* Build an Nginx image with configuration and certs.
* Provisions Pihole and Vault containers.

No configuration is performed on either Pihole or Vault. They'll still need be setup via the UI was with a manual installation.

Nginx listens to two address:
https://vault.internal
https://pihole.internal

Vault stores (encypted) data and secrets in vault-file. Pihole stores its volumes in pihole.

## Useful Vault Commands

export VAULT_TOKEN="token_here"
export VAULT_ADDR="http://vault.test.internal"

vault kv list secret/
vault kv put secret/foo password=value
