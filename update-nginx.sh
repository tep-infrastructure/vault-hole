#!/bin/bash
set -e

echo "Updating nginx reverse proxy."

docker pull nginx:latest
docker build -t nginx-proxy nginx-proxy/.

docker rm nginx-proxy-test -f > /dev/null | true

echo "Creating test container"

docker run --name nginx-proxy-test \
   -d \
   -p 1680:80/tcp \
   --network vault-hole-network \
   nginx-proxy

sleep 10
response=$(curl -H "HOST: test.internal" --write-out '%{http_code}' --silent --output /dev/null localhost:1680)

if [ "$response" == "204" ]; then

   echo "Test successful, creating proxy."
   docker rm nginx-proxy -f > /dev/null | true
   docker rm nginx-proxy-test -f > /dev/null | true
   docker run --name nginx-proxy \
      -d \
      -p 80:80/tcp \
      -p 443:443/tcp \
      --restart unless-stopped \
      --network vault-hole-network \
      nginx-proxy

else
   echo "Test failed, non successful response from test.internal, status code: '$response'."
   echo "Docker logs from 'sudo docker logs nginx-proxy-test'."

   docker logs nginx-proxy-test
fi

docker system prune --all --force

echo "Completed update script."
