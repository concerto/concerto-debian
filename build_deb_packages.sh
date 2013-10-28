#!/bin/bash
# this script will build deb packages (full and lite) for the latest tag in the concerto repo

function update_local_repo() {
  # $1 is full or lite
  if [ "${1}" != "full" ] && [ "${1}" != "lite" ]; then
    echo "don't know what to update -- ${1} ??"
    exit 1
  fi

  echo "  updating concerto_${1}'s local repo..."
  cd concerto_${1}
  cd usr/share/concerto
  git reset --hard -q
  git checkout master -q
  git pull origin master -q
  git checkout $version -q
  localversion="$(git describe --always --tags)"
  cd ../../..
  sed -i -e "s/^.*Version.*$/Version: ${control_version}/" DEBIAN/control
  echo "  local repo at ${localversion}"
  cd ..
}

function build_package() {
  # $1 is full or lite
  if [ "${1}" != "full" ] && [ "${1}" != "lite" ]; then
    echo "don't know what to build -- ${1} ??"
    exit 1
  fi

  # build package 
  echo "  building package..."
  fakeroot dpkg-deb --build concerto_${1} debs
  echo "  checking package... (results logged to: ${1}_lintian.log)"
  lintian -i --show-overrides debs/concerto-${1}_${control_version}_all.deb > ${1}_lintian.log
  echo "    $(grep "E: " ${1}_lintian.log | wc -l) errors"
  grep "E: " ${1}_lintian.log | sed 's/^/      /'
  echo "    $(grep "W: " ${1}_lintian.log | wc -l) warnings"
  grep "W: " ${1}_lintian.log | sed 's/^/      /'
  echo "    $(grep "O: " ${1}_lintian.log | wc -l) overrides"
}

function set_permissions() {
  # $1 is full or lite
  if [ "${1}" != "full" ] && [ "${1}" != "lite" ]; then
    echo "don't know what to set permissions for -- ${1} ??"
    exit 1
  fi

  cd concerto_${1}
  echo "  setting permissions for control files..."
  chmod 644 DEBIAN/*
  chmod 755 DEBIAN/config DEBIAN/postinst DEBIAN/postrm DEBIAN/preinst DEBIAN/prerm
  chmod 755 etc/init.d/concerto
  if [ -f etc/apache2/sites-available/concerto.conf ]; then
    chmod 644 etc/apache2/sites-available/concerto.conf
  fi
  chmod 644 ./usr/share/lintian/overrides/concerto-${1}
  #echo "  setting directories to 755..."
  find ./ -type d | xargs chmod 755
  #echo "  setting files to 644..."
  find ./usr/share/concerto -type f -perm 664 | xargs chmod 644
  find ./usr/share/concerto -regextype posix-awk -regex "(.*\.png|.*\.jpg|.*\.ttf|.*\.pdf|.*\.eot|.*\.svg|.*\.woff)" | xargs chmod 644
  chmod 644 ./usr/share/doc/concerto-${1}/*
  #echo "  setting files to 755..."
  find ./usr/share/concerto -type f -perm 775 -exec chmod 755 '{}' \;
  cd ..
}

function create_dbtemplate() {
  # construct a template for the dbconfig-generate-include process
  cat concerto_full/usr/share/concerto/config/database.yml.mysql >/tmp/$$.db1
  sed '/^production:/,/^[ \t]*$/ { s/my_db_name/_DBC_DBNAME_/ }' /tmp/$$.db1 > /tmp/$$.db2
  sed '/^production:/,/^[ \t]*$/ { s/my_user_name/_DBC_DBUSER_/ }' /tmp/$$.db2 > /tmp/$$.db3
  sed '/^production:/,/^[ \t]*$/ { s/my_password/_DBC_DBPASS_/ }' /tmp/$$.db3 > concerto_full/usr/share/concerto/config/database.dbctemplate
  chmod 644 concerto_full/usr/share/concerto/config/database.dbctemplate
  rm /tmp/$$.db1 /tmp/$$.db2 /tmp/$$.db3
}

function copy_service_script() {
  # $1 is full or lite
  if [ "${1}" != "full" ] && [ "${1}" != "lite" ]; then
    echo "don't know what to set permissions for -- ${1} ??"
    exit 1
  fi

  echo "  copying service script from repo... "
  mkdir -p concerto_${1}/etc/init.d
  cp concerto_${1}/usr/share/concerto/concerto-init.d concerto_${1}/etc/init.d/concerto
  # remove it from the repo directory so the packager doesnt complain
  rm concerto_${1}/usr/share/concerto/concerto-init.d
}

# ---------------------------------------------------
# main
# ---------------------------------------------------
# get options
# run with -v master      to generate a package based on the master branch
#
# Although you could also use this to build a prior tagged version, that's not 
# recommended because there may have been changes to this build script since then.

override_version=""
while getopts ":v:" opt; do
  case $opt in
    v)
      override_version="${OPTARG}"
      ;;
    \?)
      echo "invalid option: -${OPTARG}" >&2
      exit 1;
      ;;
    :)
      echo "option -${OPTARG} requires an argument" >&2
      exit 1;
      ;;
  esac
done

# ---------------------------------------------------
# Fetch Concerto version tag from Github and read the flatfile for the number
# ---------------------------------------------------
ruby get_version_tag.rb
version=`cat VERSION`
if [ "${override_version}" != "" ]; then
  echo -e "\nBuilding packages for VERSION ${override_version} but repo is at ${version} !!\n"
  version="${override_version}"
else
  echo -e "\nBuilding packages for VERSION ${version}\n"
fi

# update the control_version variable which is used for buidling the package
if [[ "${version}" =~ ^([0-9]\.){3}.+ ]]; then
  # this is a version tag
  control_version="${version}"
else
  control_version="0.0.0.${version}"
fi

# ---------------------------------------------------
# init and update the submodules if needed
# ---------------------------------------------------
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

# ---------------------------------------------------
echo -e "\nBuilding concerto-full package...\n"
# ---------------------------------------------------
update_local_repo 'full'
create_dbtemplate
copy_service_script 'full'
set_permissions 'full'
build_package 'full'


# ---------------------------------------------------
echo -e "\nBuilding concerto-lite package...\n"
# ---------------------------------------------------
update_local_repo 'lite'
copy_service_script 'lite'
set_permissions 'lite'
build_package 'lite'


# ---------------------------------------------------
echo -e "\nPreparing Packages for Deployment...\n"
# ---------------------------------------------------

echo "  removing old packaging..."
rm -rf packages.tar.gz packages/
mkdir -p packages/conf
cp distributions packages/conf/
cd packages
echo "  preparing concerto_full package..."
reprepro --component main --ask-passphrase -vb . includedeb raring ../debs/concerto-full_${control_version}_all.deb
echo "  preparing concerto_lite package..."
reprepro --component main --ask-passphrase -vb . includedeb raring ../debs/concerto-lite_${control_version}_all.deb
cd ..
tar -czf packages.tar.gz packages

echo -e "\nfinished"
