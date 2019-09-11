# ALWAYS REBUILD THE IMAGE so you get the latest concerto-debian
FROM debian
EXPOSE 80

# prepare image for installing any service (in case we want to test installation of concerto)
# https://stackoverflow.com/a/48782486/1778068
RUN echo exit 0 >/usr/sbin/policy-rc.d

RUN apt update && apt install -y -q git curl vim gpg lintian dbconfig-common reprepro ruby webfs dialog apt-utils procps

RUN git clone https://github.com/concerto/concerto-debian
RUN mkdir -p /concerto-debian/packages
RUN sed -i 's/web_port=.*/web_port="80"/g' /etc/webfsd.conf
RUN sed -i 's/web_root=.*/web_root="\/concerto-debian\/"/g' /etc/webfsd.conf

# generate a sample key for our testing our deb via our sample apt repository
COPY scripts/sample_key.sh /tmp/
RUN chmod u+x /tmp/sample_key.sh && /tmp/sample_key.sh 

# prepare add_repo.sh for our test environment
COPY scripts/add_repo.sh /concerto-debian/add_repo.sh
# change it to point to the builder docker image
RUN sed -i "s/dl.concerto-signage.org/builder/g" /concerto-debian/add_repo.sh
# remove sudo since docker tests run as root
RUN sed -i "s/sudo / /g" /concerto-debian/add_repo.sh

# HACK! change to always use master from concerto
# RUN sed -i 's/\$version/master/' /concerto-debian/build-scripts/debian-common.sh

# create the deb packages, sleep to keep the container running
CMD cd concerto-debian && ./build_deb_packages.sh && service webfs restart && echo "running until stopped..." && sleep infinity
