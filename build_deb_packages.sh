#!/bin/bash
# this script will build deb packages (full and lite) for the latest tag in the concerto repo

source "./build-scripts/debian-common.sh"

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
# $version is the version tag of concerto from github that we want to build for
# $control_version is used for naming the deb package
ruby get_version_tag.rb
version=`cat VERSION`

# $override_version is the user specified version/branch to pull from concerto github.
# If this is blank then we will use $version, if it is "master" then we will use "master" and
# set the $control_version to 0.0.0 since that needs a number.
if [ "${override_version}" = "master" ]; then
  echo -e "\nBuilding packages for VERSION ${override_version} but repo is at ${version} !!\n"
  version="${override_version}"
  control_version="0.0.0"
elif [ "${override_version}" != "" ]; then
  echo -e "\nBuilding packages for VERSION ${override_version} but repo is at ${version} !!\n"
  version="${override_version}"
  control_version="${version}"
else
  echo -e "\nBuilding packages for VERSION ${version}\n"
  control_version="${version}"
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
echo "  preparing concerto_full packages..."
reprepro --component main --ask-passphrase -vb . includedeb buster ../debs/concerto-full_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb bionic ../debs/concerto-full_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb xenial ../debs/concerto-full_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb stretch ../debs/concerto-full_${control_version}_all.deb
echo "  preparing concerto_lite packages..."
reprepro --component main --ask-passphrase -vb . includedeb buster ../debs/concerto-lite_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb bionic ../debs/concerto-lite_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb xenial ../debs/concerto-lite_${control_version}_all.deb
reprepro --component main --ask-passphrase -vb . includedeb stretch ../debs/concerto-lite_${control_version}_all.deb
cd ..
tar -czf packages.tar.gz packages
cd packages
dpkg-scanpackages . | gzip -9c >/tmp/Packages.gz
mv /tmp/Packages.gz ./
cd ..

# We have a sample.key when running the builder.dockerfile.
# If we have a sample key then put it out there so it can be used by add_repo.sh when testing,
# and put the add_repo.sh script out there as well.
if [ -f sample.key ]; then
  echo "copying sample.key to packages directory for testing"
  cp sample.key packages/concerto_deb_public.key
  echo "copying add_repo.sh to packages directory for testing"
  cp scripts/add_repo.sh packages/add_repo.sh
  # change it to point to the builder docker image
  sed -i "s/dl.concerto-signage.org/builder/g" packages/add_repo.sh
  # remove sudo since docker tests run as root
  sed -i "s/sudo / /g" packages/add_repo.sh
fi

echo -e "\nfinished"
