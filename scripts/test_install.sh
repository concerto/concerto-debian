#!/bin/bash
while [ $(nmap builder -p 80 --open | grep "tcp open" | wc -l) != "1" ]; do
  echo "waiting for builder's apt repo to come online..."
  sleep 5
done

wget -O - http://builder/sample.key | apt-key add - 
apt update
apt install -y concerto-full

# wait forever so docker container keeps running so we can browse to the site and verify it
echo "ready for you to verify concerto installation"
sleep infinity
