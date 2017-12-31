#!/bin/bash

sudo apt-get install apt-transport-https
wget -O - http://dl.concerto-signage.org/concerto_deb_public.key | sudo apt-key add -
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
echo 'deb http://dl.concerto-signage.org/packages/ stretch main\ndeb https://oss-binaries.phusionpassenger.com/apt/passenger stretch main' > /tmp/concerto.list
sudo cp -fr /tmp/concerto.list /etc/apt/sources.list.d/
rm /tmp/concerto.list
sudo apt-get update
