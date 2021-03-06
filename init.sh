#!/bin/bash
set -e

generateCert () {
   if [ ! -f "$1.key" ]; then
      echo "Generating cert for $1"

      openssl genrsa -out $1.key 2048
      openssl req -new -sha256 -key $1.key -subj "/C=UK/L=London/O=internal/CN=$1" -out $1.csr
      openssl x509 -req -in $1.csr -CA internalCA.crt -CAkey internalCA.key -CAcreateserial -out $1.crt -days 3650 -sha256
   fi
}

sudo apt-get update
sudo apt-get install -y software-properties-common apt-transport-https curl net-tools

## docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

## hashicorp repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io git vim && \
sudo apt-get install -y vault && \
sudo systemctl enable docker && sudo systemctl start docker

sudo usermod -aG docker $USER

mkdir nginx-proxy/certs -p
cd nginx-proxy/certs
if [ ! -f internalCA.key ]; then
   # root cert, 'internal'
   openssl genrsa -des3 -out internalCA.key 4096 && \
   openssl req -x509 -new -nodes -key internalCA.key -sha256 -days 3650 -subj "/C=UK/L=London/O=internal/OU=internal/CN=internal" -out internalCA.crt
fi

generateCert 'pihole.internal'
generateCert 'vault.internal'
generateCert 'internal'
cd ../../

echo "Building and pulling docker images."

sudo docker build -t nginx-proxy nginx-proxy/.
sudo docker pull pihole/pihole:latest
sudo docker pull vault:latest

echo "Configuring systemd resolve."

# systemd-resolved needs to be convinced not to block port 53 - https://github.com/pi-hole/docker-pi-hole#installing-on-ubuntu
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
sudo systemctl restart systemd-resolved

echo "Cleaning previous containers."

sudo docker rm pihole -f > /dev/null | true
sudo docker rm vault -f > /dev/null | true
sudo docker rm nginx-proxy -f > /dev/null | true
sudo docker rm nginx-proxy-test -f > /dev/null | true
sudo docker network rm vault-hole-network > /dev/null | true
sudo docker network create vault-hole-network

echo "Creating containers."

sudo docker run --name pihole \
   -d \
   -p 8080:80/tcp \
   -p 53:53/tcp \
   -p 53:53/udp \
   -p 67:67/udp \
   -e TZ=Europe/London \
   -v "$PWD/pihole/etc-pihole/:/etc/pihole/" \
   -v "$PWD/pihole/etc-dnsmasq.d/:/etc/dnsmasq.d" \
   --restart unless-stopped \
   --cap-add=NET_ADMIN \
   --dns=127.0.0.1 \
   --dns=8.8.8.8 \
   --network vault-hole-network \
   pihole/pihole:latest

sudo docker run --name vault \
   -d \
   -v $PWD/vault:/vault/config \
   -v $PWD/vault-file:/vault/file \
   --cap-add=IPC_LOCK \
   -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
   --restart unless-stopped \
   --network vault-hole-network \
   vault:latest server

sudo docker run --name nginx-proxy \
   -d \
   -p 80:80/tcp \
   -p 443:443/tcp \
   --restart unless-stopped \
   --network vault-hole-network \
   nginx-proxy

sudo docker system prune --all --force

echo "Completed init script."
