#Concerto-Debian
This Git repository contains everything needed to create the Concerto Debian packages **concerto-full** and **concerto-lite**.

concerto-lite
: A lightweight Concerto package that includes dependencies on ImageMagick, Ruby 1.9, and the MySQL client libraries.  It is intended for the user that wants  more control over their own web stack.  Additional, manual configuration is required to get the Concerto system running.

concerto-full
: The full Concerto package closely replicates the setup of the server virtual image. It includes dependencies on ImageMagick, Ruby 1.9, the MySQL client libraries, Apache2, and all the required libraries for Passenger. Once this package is installed, the Concerto system should be up and running.

##Building the Packages and Updating the Concerto-Signage Repository
* Make sure the following tools are installed: gpg, lintian, and reprepro.
* Make sure the GPG keychain (available from a committer) is installed in your home directory.  You'll also need the passphrase for the key.
* Run the ./build_deb_packages.sh script.
* Upload the packages.tar.gz that results to the download server and unpack it.

##Installing the Packages from the Concerto-Signage Repository
1. Run the `scripts/add_repo.sh` script and then 
2. Run `sudo apt-get install concerto-full` or specify concerto-lite instead of concerto-full, depending upon which package you want to install.
OR  
1. Add the Concerto-Signage Repository key:
    wget -O - http://dl.concerto-signage.org/concerto_deb_public.key | sudo apt-key add -
2. Add this line to /etc/apt.sources.list (or as a file in /etc/apt/sources.list.d/):
    deb http://dl.concerto-signage.org/packages/ raring main

After installation, the Concerto Apache configuration must be enabled (`sudo a2ensite concerto`) and Apache must be reloaded (`sudo service apache2 reload`). The default Apache configuration may also need to be disabled (`sudo a2dissite 000-default`).

##What do the Concerto Packages Install?
These packages will place a concerto config file in /etc/apache2/sites-available that includes Passenger and contains a reasonable Concerto vhost configuration.

In addition to the dependencies listed below, each package will place the Concerto source code in /usr/share/concerto and then perform a few post-install tasks:
* Installation of global gem dependencies listed below
* Compilation of Passenger Apache extensions
* bundle install in the vendor/bundle directory of Concerto
* Creation of mysql-based database.yml in the Concerto config directory

###Concerto Package Dependencies
* apache2-mpm-worker
* build-essential
* imagemagick
* libruby1.9.1
* ruby1.9.1-full

###Passenger Dependencies
* apache2-prefork-dev
* libcurl4-openssl-dev
* libssl-dev 
* libapr1-dev
* libaprutil1-dev
* zlib1g-dev

###ImageMagick Dependencies
* libmagickcore-dev
* libmagickwand-dev
* librmagick-ruby
* nodejs

###Concerto Gem Dependencies (Global)
* bundler-1.1.4
* daemon_controller-1.0.0
* fastthread-1.0.7
* passenger-3.0.12
* rack-1.4.1
* rake-0.9.2.2
* rmagick-2.13.1
