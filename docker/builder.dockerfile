FROM debian
EXPOSE 80

RUN apt update && apt install -y git curl vim gpg lintian dbconfig-common reprepro ruby webfs dialog apt-utils procps

RUN git clone https://github.com/concerto/concerto-debian
RUN mkdir -p /concerto-debian/packages
RUN sed -i 's/web_port=.*/web_port="80"/g' /etc/webfsd.conf
RUN sed -i 's/web_root=.*/web_root="\/concerto-debian\/packages"/g' /etc/webfsd.conf

# generate a sample key for our testing our deb via our sample apt repository
COPY scripts/sample_key.sh /tmp/
RUN chmod u+x /tmp/sample_key.sh && /tmp/sample_key.sh 

# HACK! TODO! JUST UNTIL FINISHED TESTING! - get our branch, and trust our key
RUN cd concerto-debian && git pull origin buster-update

# create the deb packages
RUN cd concerto-debian && ./build_deb_packages.sh

# sleep to keep the container running
CMD service webfs start && sleep infinity
