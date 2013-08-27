#!/bin/bash
# prepvm_for_capistrano.sh
# Prepares the concerto virtual machine image for capistrano deploys.
# Download this script to the concerto home directory, chmod +x it and
# run as sudo (for directory creation and permission and config changes).

# prompt for confirmation
clear
echo "This is a one-time script that will prepare the concerto vm image for "
echo "capistrano deploys.  It is written specifically for the concerto vm "
echo "image and should not be run on other servers."
echo -e "\nThis will:"
echo -e "  * create directories /var/webapps and ~/projects and reassign"
echo -e "    ownership to the concerto user"
echo -e "  * install the capistrano package (via apt-get) and "
echo -e "    the capistrano-tags gem"
echo -e "  * pull down the repo so we can get the capistrano scripts"
echo -e "  * copy the existing database.yml file from the old location to the"
echo -e "    new location"
echo -e "  * run the initial capistrano setup and checks and deploy, prompting "
echo -e "    to continue between each one"
echo -e "  * change the concerto apache site configuration to point to "
echo -e "    /var/webapps/concerto/current/public and restart apache"
echo -e "\nIt is a really good idea to snapshot your vm before you continue.\n"
read -p "Do you want to continue? (Y/n) " answer
answer=${answer:-Y}
if [ "$answer" != "Y" ]; then
  exit 0
fi

# make sure we are running as sudo - after prompt above so they can decide
if [ `id -u` -ne 0 ]; then
  echo "This script must be run as sudo because it creates directories and "
  echo "changes website configurations."
  exit 1
fi

# create the deploy root directory
echo "creating /var/webapps"
mkdir -p /var/webapps
chown concerto:concerto /var/webapps
chmod g+w /var/webapps

# create the project directory for concerto where we will
# kick off the deploys from
echo "creating ~/projects"
mkdir -p ~/projects
cd ~/projects

# clone the repo
echo "cloning the repo"
git clone https://github.com/concerto/concerto.git
cd concerto

# set ownership back to concerto
echo "setting ownership back to concerto"
chown -R concerto:concerto ~/projects

# install capistrano and the capistrano-tags gem
echo "installing capistrano via apt-get"
apt-get -qq -y install capistrano

echo "installing capistrano-tags gem"
gem install capistrano-tags -q --no-rdoc --no-ri

# set up cap directory structure on server with bogus password
su concerto -c "cap -S dbpwd=\"concerto\" deploy:setup"
# overwrite the default database.yml with the vm's initial config
cp /usr/share/concerto/config/database.yml /var/webapps/concerto/shared/config/
read -p "Do you want to continue with the deploy check? (Y/n) " answer
answer=${answer:-Y}
if [ "$answer" != "Y" ]; then
  exit 0
fi

# check the deploy
su concerto -c "cap deploy:check"
read -p "Do you want to continue with the deploy? It may take a few minutes to complete. (Y/n) " answer
answer=${answer:-Y}
if [ "$answer" != "Y" ]; then
  exit 0
fi

# perform the deploy
su concerto -c "cap deploy"
read -p "Do you want to change the apache site configuration to point to the new location and restart apache? (Y/n) " answer
answer=${answer:-Y}
if [ "$answer" != "Y" ]; then
  exit 0
fi

echo "changing site configuration to point to /var/webapps/concerto/current/public"
sed 's/usr\/share\/concerto/var\/webapps\/concerto\/current/g' /etc/apache2/sites-available/concerto >/tmp/$$.site_config
cp /tmp/$$.site_config /etc/apache2/sites-available/concerto
rm /tmp/$$.site_config

# restart apache since we changed the site configuration
echo "restarting web server"
service apache2 restart

echo -e "\ndone!  from here on out all you have to do to update is run:"
echo "  cap deploy"
echo "from /home/concerto/projects/concerto"
