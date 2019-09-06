#!/bin/bash
# this script will build deb packages (full and lite) for the latest tag in the concerto repo

# this is the debian release our build is based on
RELEASE="buster"
sed -i "s/Codename: .*/Codename: ${RELEASE}/g" distributions
sed -i "s/Pull: .*/Pull: ${RELEASE}/g" distributions

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
echo "  preparing concerto_full package..."
reprepro --component main --ask-passphrase -vb . includedeb ${RELEASE} ../debs/concerto-full_${control_version}_all.deb
echo "  preparing concerto_lite package..."
reprepro --component main --ask-passphrase -vb . includedeb ${RELEASE} ../debs/concerto-lite_${control_version}_all.deb
cd ..
tar -czf packages.tar.gz packages

echo -e "\nfinished"
