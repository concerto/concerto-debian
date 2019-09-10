FROM debian:buster
EXPOSE 80

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y -qq dialog gnupg2 tzdata vim wget nmap

# prepare image for installing any service (in case we want to test installation of concerto)
# https://stackoverflow.com/a/48782486/1778068
RUN echo exit 0 >/usr/sbin/policy-rc.d

RUN echo "deb http://builder buster main" >>/etc/apt/sources.list

COPY scripts/test_install.sh /
RUN chmod +x /test_install.sh
CMD /test_install.sh
