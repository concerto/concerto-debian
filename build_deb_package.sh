#!/bin/bash

#Fetch Concerto version tag from Github and read the flatfile for the number
ruby get_version_tag.rb
version=`cat VERSION`

sed -e "s/^.*Version.*$/Version: ${version}/" debian/DEBIAN/control

find ./debian -type d | xargs chmod 755
fakeroot dpkg-deb --build debian
mv debian.deb Concerto_${version}_all.deb
lintian Concerto_${version}_all.deb

rm -rf packages.tar.gz packages/
mkdir -p packages/conf
cp distributions packages/conf/
cd packages
reprepro --ask-passphrase -Vb . includedeb precise /home/august/concerto-debian/Concerto_${version}_all.deb
cd ..
tar -czvf packages.tar.gz packages
