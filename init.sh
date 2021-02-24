#!/bin/bash
set -e

generateCert () {
  echo "Generating cert for $1"

   openssl genrsa -out $1.key 2048
   openssl req -new -sha256 -key $1.key -subj "/C=UK/L=London/O=internal/CN=$1" -out $1.csr
   openssl x509 -req -in $1.csr -CA internalCA.crt -CAkey internalCA.key -CAcreateserial -out $1.crt -days 3650 -sha256
}

sudo apt-get update
sudo apt-get install -y apt-transport-https curl

## docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

## hashicorp repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io vault git vim && \
sudo systemctl enable docker && sudo systemctl start docker

sudo usermod -aG docker $USER

mkdir nginx-proxy/certs -p
cd nginx-proxy/certs
if [ ! -f internalCA.key ]; then
   # root cert, 'internal'
   openssl genrsa -des3 -out internalCA.key 4096 && \
   openssl req -x509 -new -nodes -key internalCA.key -sha256 -days 3650 -subj "/C=UK/L=London/O=internal/OU=internal/CN=internal" -out internalCA.crt

   generateCert 'pihole.internal'
   generateCert 'vault.internal'
fi
cd ../../

sudo docker build -t nginx-proxy nginx-proxy/.
sudo docker pull pihole/pihole:latest
sudo docker pull vault:latest


# systemd-resolved needs to be convinced not to block port 53 - https://github.com/pi-hole/docker-pi-hole#installing-on-ubuntu
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf

sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
sudo systemctl restart systemd-resolved

sudo docker rm pihole -f | true
sudo docker run --name pihole \
   -d \
   -p 53:53/tcp \
   -p 53:53/udp \
   -p 67:67/udp \
   -p 8080:80/tcp \
   -e TZ=Europe/London \
   -v "$PWD/pihole/etc-pihole/:/etc/pihole/" \
   -v "$PWD/pihole/etc-dnsmasq.d/:/etc/dnsmasq.d" \
   --restart unless-stopped \
   --cap-add=NET_ADMIN \
   --dns=127.0.0.1 \
   --dns=8.8.8.8 \
   pihole/pihole:latest

sudo docker rm vault -f | true
sudo docker run --name vault \
   -d \
   -p 8200:8200/tcp \
   -v $PWD/vault:/vault/config \
   -v $PWD/vault-file:/vault/file \
   --cap-add=IPC_LOCK \
   -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
   --restart unless-stopped \
   vault:latest server

sudo docker rm nginx-proxy -f | true
sudo docker run --name nginx-proxy \
   -d \
   -p 80:80/tcp \
   -p 443:443/tcp \
   --restart unless-stopped \
   nginx-proxy
