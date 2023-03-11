#!/bin/bash

set -e

IMAGE_NAME="pihole/pihole:2023.02.2"

docker image pull $IMAGE_NAME 

docker rename pihole pihole_backup
docker stop pihole_backup

docker run --name pihole \
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
   $IMAGE_NAME

echo "Update completed. It may take a few minutes for Pihole to restart."
echo "The old pihole is now called pihole_backup and can be restored manually."

