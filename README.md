# Concerto-Debian
This Git repository contains everything needed to create the Concerto Debian packages.

**concerto-lite**
: A lightweight Concerto package that includes dependencies on ImageMagick, Ruby > 2.1, and the MySQL client libraries.  It is intended for the user that wants  more control over their own web stack.  Additional, manual configuration is required to get the Concerto system running.

**concerto-full**
: The full Concerto package closely replicates the setup of the server virtual image. It includes dependencies on ImageMagick, Ruby > 2.1, the MySQL client libraries, Apache2, and all the required libraries for Passenger. Once this package is installed, the Concerto system should be up and running.

## Building the Packages and Updating the Concerto-Signage Repository
* Make sure the following tools are installed: gpg, lintian, dbconfig-common, and reprepro.
* Make sure the GPG keychain (available from a committer) is installed in your home directory.  You'll also need the passphrase for the key.
* Run the `./build_deb_packages.sh` script.
* Upload the `packages.tar.gz` file, that is produced, to the download server and unpack it.

### Using a docker image for building and testing

```
cd docker
docker-compose up
```

This will create an instance (builder) that will create the packages and place them in a local apt repository (signed with a sample key) for testing.  You may want to rebuild the packages or specify which version of concerto you want to build packages for.  You can do this by getting into the container with `docker exec -it builder bash -l` and then going into the `/concerto-debian` directory and running the `./build_deb_packages.sh` script as mentioned in this document.

This will also create a test instances for installing the full and lite versions on debian and ubuntu.  You can use
 `docker container inspect busterfull` to find out the ip address to browse to, to verify the application after 
 installation.  Each of these test instances will require some user interaction during the installation.

Running `docker-compose down` afterwards will clean up the images.

_Once you have approved the package, you need to either resign it with the actual key, or replace the sample key with the real
key and rebuild the packages._

## Installing the Packages from the Concerto-Signage Repository
1. Run the `scripts/add_repo.sh` script and then
2. Run `sudo apt-get install concerto-full` or specify concerto-lite instead of concerto-full, depending upon which package you want to install.

OR  

1. Add the Concerto-Signage Repository key: `wget -O - http://dl.concerto-signage.org/concerto_deb_public.key | sudo apt-key add -`
2. Add this line to /etc/apt/sources.list (or as a file in /etc/apt/sources.list.d/):
```
    deb http://dl.concerto-signage.org/packages/ stretch main
```

After installation, the Concerto Apache configuration must be enabled (`sudo a2ensite concerto`) and Apache must be reloaded (`sudo service apache2 reload`). The default Apache configuration may also need to be disabled (`sudo a2dissite 000-default`).

## What do the Concerto Packages Install?
In addition to the dependencies listed below, each package will place the Concerto source code in /usr/share/concerto and then perform a few post-install tasks:
* Installation of global gem dependencies listed below
* Compilation of Passenger Apache extensions
* bundle install in the vendor/bundle directory of Concerto
* Creation of mysql-based database.yml in the Concerto config directory
* Installation of a service script: /etc/init.d/concerto

The concerto-full package will place a concerto site configuration file in /etc/apache2/sites-available that includes Passenger and contains a reasonable Concerto vhost configuration. It will also disable the 000-default site.

### Concerto Package Dependencies
* build-essential
* imagemagick
* libruby1.9.1
* ruby2.1-full

### Passenger Dependencies
* apache2-mpm-worker
* apache2-prefork-dev
* libcurl4-openssl-dev
* libssl-dev
* libapr1-dev
* libaprutil1-dev
* zlib1g-dev

### ImageMagick Dependencies
* libmagickcore-dev
* libmagickwand-dev
* librmagick-ruby
* nodejs

### Concerto Gem Dependencies (Global)
* bundler-1.1.4
* daemon_controller-1.0.0
* fastthread-1.0.7
* passenger-3.0.12
* rack-1.4.1
* rake-0.9.2.2
* rmagick-2.13.1
