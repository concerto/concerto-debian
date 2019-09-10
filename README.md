# Concerto-Debian

This Git repository contains everything needed to create the Concerto Debian packages.

**concerto-lite**
: A lightweight Concerto package that includes dependencies on ImageMagick, Ruby > 2.3, and the MySQL client libraries.  It is intended for the user that wants more control over their own web stack.  Additional, manual configuration is required to get the Concerto system running.

**concerto-full**
: The full Concerto package closely replicates the setup of the server virtual image. It includes dependencies on ImageMagick, Ruby > 2.3, the MySQL client libraries, Apache2, and all the required libraries for Passenger. Once this package is installed, the Concerto system should be up and running.

## Building the Packages Locally and Updating the Concerto-Signage Repository

* Make sure the following tools are installed: gpg, lintian, dbconfig-common, and reprepro.
* Make sure the GPG keychain (available from a committer) is installed in your home directory.  You'll also need the passphrase for the key.
* Run the `./build_deb_packages.sh` script.
* Upload the `packages.tar.gz` file, that is produced, to the download server and unpack it.

## Building the Packages Using Docker (and Testing them)

This section explains how you can build the packages in a docker container, and use other docker containers to test the packages. Make sure you have docker and git installed on your local machine.  Then git clone this concerto-debian repository, and 

```
cd concerto-debian/docker
docker-compose up --build --force-recreate
```

This will create an image for building the deb packages and hosting them in a local apt repository.  It will also create additional images for testing the installation of the packages on various distributions.

The first container (docker_builder_1) will create a sample gpg key, create and sign the packages, and serve them in a local apt repository for testing.  You may want to rebuild the deb packages or specify which version of concerto you want to build packages for (it builds the latest concerto version by default).  You can do this by getting into the container with `docker exec -it docker_builder_1 bash -l` and then going into the `/concerto-debian` directory and running the `./build_deb_packages.sh` script as mentioned in this document.

The testing containers (docker_buster_1, for example) have a dependency on docker_builder_1, and will wait until it sees it's web server up and running (see the test_install.sh script that each testing container runs at startup) before trying to update and install concerto-full.  You can use `docker container inspect docker_buster_1` to find out the ip address so you can verify the concerto installation with your browser.

If you run `docker container ls` you should see each test container and the builder listed.  When a container fails it will no longer be running.  Once docker-compose has finished building them and the start up scripts have finished, this is an easy way to see if they have all successfully installed concerto-full.  You can check out the logs for one that failed by running `docker log docker_buster_1` for example.  You can also bring the failed one back up so you can get into it and troubleshoot by using `docker container start docker_buster_1` and then `docker exec -it docker_buster_1 bash -l`.

Running `docker-compose down` afterwards will clean up the containers, but the images will still remain. You can remove the images if you want by running `docker image rm docker_buster` for each of them.

Once you have tested and verified the packages, you will need to either resign it with the actual gpg key, or replace the sample gpg key with the real key and rebuild the packages.  To replace the gpg key, scp the real GPG Keychain into the builder container and unzip it into a directory such as /tmp/ and then run `gpg --import /tmp/.gnupg/secring.gpg` you will need to enter the passphrase.  Then run `gpg --list-key` and find the numeric_identifier for the concerto key and change the concerto-debian/distributions file and replace each occurence of `SignWith: Yes` to `SignWith: numeric_identifier`. When that value is Yes, it chooses the first key it finds, when it is a specific identifier then it uses the specified key.  If you are going to test it again after updating the key, you will also need to export it `gpg -a -o /concerto-debian/sample.key --export concerto@concerto-signage.org`.  Then run the ./build_deb_packages.sh again, and it will prompt you for the passphrase. Remember to upload the packages.tar.gz file to the real apt repository.

### Changes for a Different Distribution

To prepare for a different release of Debian (or Ubuntu), you will need to change the distributions file and the build_deb_packages.sh file.  The concerto_{full|lite}/DEBIAN/control file may also need tweaked based on what dependencies have changed. And for testing, you'll probably want to change or add one of the docker/test.*.dockerfiles and perhaps the docker-compose.yml file.

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

In addition to the dependencies listed in the concerto_{full|lite}/DEBIAN/control files, each package will place the Concerto source code in /usr/share/concerto and then perform a few post-install tasks:

* Installation of global gem dependencies listed below
* Compilation of Passenger Apache extensions
* bundle install in the vendor/bundle directory of Concerto
* Creation of mysql-based database.yml in the Concerto config directory
* Installation of a service script: /etc/init.d/concerto

The concerto-full package will place a concerto site configuration file in /etc/apache2/sites-available that includes Passenger and contains a reasonable Concerto vhost configuration. It will also disable the 000-default site.

