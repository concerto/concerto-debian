#!/bin/bash

sudo apt-get install apt-transport-https
wget -O - http://dl.concerto-signage.org/concerto_deb_public.key | sudo apt-key add -
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7

# try to determine codename since not all distros (especially docker images) have lsb_release installed
CODENAME=$(lsb_release -cs)
if [ "$CODENAME" = "" ]; then
  CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2)
  if [ "$CODENAME" = "" ]; then
    # fallback to stretch since xenial, bionic, and buster have os-release with VERSION_CODENAME
    CODENAME="stretch"
  fi
fi
echo "deb http://dl.concerto-signage.org/packages/ ${CODENAME} main\ndeb https://oss-binaries.phusionpassenger.com/apt/passenger ${CODENAME} main" > /tmp/concerto.list
sudo cp -fr /tmp/concerto.list /etc/apt/sources.list.d/
rm /tmp/concerto.list
sudo apt-get update
