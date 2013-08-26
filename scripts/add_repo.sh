#!/bin/bash

wget -O - http://dl.concerto-signage.org/concerto_deb_public.key | sudo apt-key add -

echo 'deb http://dl.concerto-signage.org/packages/ raring main' > /tmp/concerto.list
sudo cp -fr /tmp/concerto.list /etc/apt/sources.list.d/
rm /tmp/concerto.list
sudo apt-get update
