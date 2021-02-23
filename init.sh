#!/bin/bash
set -e

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https curl git net-tools xclip


## Docker

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io && \
sudo systemctl enable docker && sudo systemctl start docker

#sudo groupadd docker
sudo usermod -aG docker $USER
# to refresh login permissions. may not be necessary
#newgrp docker
