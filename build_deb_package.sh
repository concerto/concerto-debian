#!/bin/bash

find ./debian -type d | xargs chmod 755
fakeroot dpkg-deb --build debian
mv debian.deb Concerto_0.1-1_all.deb
lintian Concerto_0.1-1_all.deb

rm -rf packages.tar.gz packages/
mkdir -p packages/conf
cp distributions packages/conf/
cd packages
reprepro --ask-passphrase -Vb . includedeb precise /home/august/concerto-debian/Concerto_0.1-1_all.deb
cd ..
tar -czvf packages.tar.gz packages
