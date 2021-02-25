#!/bin/bash
set -e

echo "Updating nginx reverse proxy."

sudo docker pull nginx:latest
sudo docker build -t nginx-proxy nginx-proxy/.

sudo docker rm nginx-proxy-test -f > /dev/null | true

echo "Creating test container"

sudo docker run --name nginx-proxy-test \
   -d \
   -p 1680:80/tcp \
   --network vault-hole-network \
   nginx-proxy

echo "curl"
response=$(curl -H "HOST: test.internal" --write-out '%{http_code}' --silent --output /dev/null localhost:1680) | true
echo "Test response: $response"

if [ "$response" == "204" ]; then

   echo "Test successful, creating proxy."
   sudo docker rm nginx-proxy -f > /dev/null | true
   sudo docker rm nginx-proxy-test -f > /dev/null | true
   sudo docker run --name nginx-proxy \
      -d \
      -p 80:80/tcp \
      -p 443:443/tcp \
      --restart unless-stopped \
      --network vault-hole-network \
      nginx-proxy

else
   echo "Test failed, non successful response from test.internal, status code: '$response'."
   echo "Docker logs from 'sudo docker logs nginx-proxy-test'."

   sudo docker logs nginx-proxy-test
fi


echo "Completed init script."
