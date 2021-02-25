# Vault Hole

[PiHole](https://pi-hole.net/) and [Vault](https://www.vaultproject.io/), together as one.

This project aims to host Pihole and Vault together on one device behind an Nginx reverse proxy. All 3 components are in Docker containers.

**This project has only been tried on Ubuntu 20.04. It might work on other Debian based systems but I haven't tried.**

`init.sh` does a few things:

* Adds the Docker and Hashicorp repos.
* Installs Docker and other useful utilities.
* Installs Vault CLI (Vault CLI isn't directly used, but is useful for admin).
* Generates some self signed certificates.
* Build an Nginx image with configuration and certs.
* Provisions Pihole, Vault and Nginx containers.

No configuration is performed on either Pihole or Vault. They'll still need be setup via the UI was with a manual installation.

Nginx listens to two address:
* https://vault.internal
* https://pihole.internal

Vault stores (encypted) data and secrets in vault-file. Pihole stores its volumes in pihole.

## Useful Vault Commands

```bash
export VAULT_TOKEN="token_here"
export VAULT_ADDR="http://vault.internal"

vault kv list secret/
vault kv put secret/foo password=value
```

## Other Setup

### Static IP

A PiHole works best with a static IP address, but there seems to be several ways of doing that change from system to system.

#### If `/etc/dhcpcd.conf` exists

Append the following to `/etc/dhcpcd.conf`:

```bash
interface eth0
        static ip_address=192.168.1.10/24
        static routers=192.168.1.1
        static domain_name_servers=8.8.8.8 8.8.4.4
```

Change IP address and router as necessary.

#### If `/etc/netplan` exists

Change the yaml file within (the exact name of the file seems fluid) to match something like this:

```yaml
network:
    ethernets:
        eth0:
            dhcp4: no
            dhcp6: no
            addresses: [192.168.1.10/24]
            gateway4: 192.168.1.1
            nameservers:
                    addresses: [8.8.8.8,8.8.4.4]
            optional: true
    version: 2
```

### Change hostname

```
sudo hostnamectl set-hostname vault-hole
echo "127.0.1.1" | sudo tee /etc/hosts -a
```

### Add user

```bash
sudo adduser -G sudo <new_user>
```
