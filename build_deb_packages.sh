#!/bin/bash

#Fetch Concerto version tag from Github and read the flatfile for the number
ruby get_version_tag.rb
version=`cat VERSION`

cd concerto_full/usr/share/concerto
git checkout .
git pull
git checkout $version
cd ../../../../
sed -i -e "s/^.*Version.*$/Version: ${version}/" concerto_full/DEBIAN/control

cd concerto_lite/usr/share/concerto
git checkout .
git pull
git checkout $version
cd ../../../../
sed -i -e "s/^.*Version.*$/Version: ${version}/" concerto_lite/DEBIAN/control

find ./concerto_full -type d | xargs chmod 755
fakeroot dpkg-deb --build concerto_full
mv concerto_full.deb concerto_full_${version}_all.deb
lintian concerto_full_${version}_all.deb

find ./concerto_lite -type d | xargs chmod 755
fakeroot dpkg-deb --build concerto_lite
mv concerto_lite.deb concerto_lite_${version}_all.deb
lintian concerto_lite__${version}_all.deb

rm -rf packages.tar.gz packages/
mkdir -p packages/conf
cp distributions packages/conf/
cd packages
reprepro --ask-passphrase -Vb . includedeb raring ~/concerto-debian/concerto_full_${version}_all.deb
reprepro --ask-passphrase -Vb . includedeb raring ~/concerto-debian/concerto_lite_${version}_all.deb
cd ..
tar -czvf packages.tar.gz packages
