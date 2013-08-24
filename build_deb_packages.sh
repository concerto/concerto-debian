#!/bin/bash

# Fetch Concerto version tag from Github and read the flatfile for the number
ruby get_version_tag.rb
version=`cat VERSION`

echo -e "\nBuilding packages for VERSION ${version}\n"

# init and update the submodules if needed
if [[ ! -f concerto_full/usr/share/concerto/.git || ! -f concerto_lite/usr/share/concerto/.git ]]; then
  echo "  initializing and updating submodules..."
  git submodule init && git submodule update
  if [ $? -ne 0 ]; then
    # it failed
    exit 1
  fi
else 
  echo "  submodules dont require initializing"
fi

# update concerto_full's local repo to the version requested
echo "  updating concerto_full's local repo..."
cd concerto_full

cd usr/share/concerto
git reset --hard -q
git checkout master -q
git pull origin master -q
git checkout $version -q
localversion="$(git describe --always --tags)"
cd ../../../
sed -i -e "s/^.*Version.*$/Version: ${version}/" DEBIAN/control
echo "  local repo at ${localversion}"

# set permissions
echo "  setting permissions for control files..."
cd DEBIAN
chmod 644 *
chmod 755 config postinst postrm preinst prerm
cd ../etc/init.d
chmod 755 concerto
cd ../..
chmod 644 etc/apache2/sites-available/concerto

echo "  setting directories to 755..."
find ./ -type d | xargs chmod 755
chmod 755 usr/local/bin/concerto-install-mysql
echo "  setting files to 644..."
find ./usr/share/concerto -type f -perm 664 | xargs chmod 644
find ./usr/share/concerto -regextype posix-awk -regex "(.*\.png|.*\.jpg|.*\.ttf|.*\.pdf|.*\.eot|.*\.svg|.*\.woff)" | xargs chmod 644
chmod 755 ./usr/share/concerto/concerto
echo "  setting files to 755..."
find ./usr/share/concerto -type f -perm 775 | xargs chmod 755
cd ..

# build package 
echo "  building package..."
fakeroot dpkg-deb --build concerto_full
echo "  renaming package..."
mv concerto_full.deb concerto_full_${version}_all.deb

echo "  checking package..."
lintian -i concerto_full_${version}_all.deb > full_lintian.log
echo "  $(grep "E: " full_lintian.log | wc -l) errors"
grep "E: " full_lintian.log | sed 's/^/    /'
echo "  $(grep "W: " full_lintian.log | wc -l) warnings"
grep "W: " full_lintian.log | sed 's/^/    /'

exit 0


# update concerto_lite's local repo to the version requested
echo "  updating concerto_lite's local repo..."
cd concerto_lite/usr/share/concerto
git checkout master
git pull origin master
git checkout $version
cd ../../../../
sed -i -e "s/^.*Version.*$/Version: ${version}/" concerto_lite/DEBIAN/control

# set permissions, build package and check it
echo "  setting directories to 755..."
find ./concerto_lite -type d | xargs chmod 755
echo "  building package..."
fakeroot dpkg-deb --build concerto_lite
echo "  renaming package..."
mv concerto_lite.deb concerto_lite_${version}_all.deb
echo "  checking package..."
lintian concerto_lite__${version}_all.deb > lite_lintian.log

# bundle packages for deployment
echo "  bundling packages for deployment"
rm -rf packages.tar.gz packages/
mkdir -p packages/conf
cp distributions packages/conf/
cd packages
reprepro --ask-passphrase -Vb . includedeb raring ~/concerto-debian/concerto_full_${version}_all.deb
reprepro --ask-passphrase -Vb . includedeb raring ~/concerto-debian/concerto_lite_${version}_all.deb
cd ..
tar -czvf packages.tar.gz packages

echo "done"
