FROM debian:buster
EXPOSE 80

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y dialog gnupg2 tzdata vim wget
RUN wget -O - http://builder/sample.key | apt-key add -

# prepare image for installing any service (in case we want to test installation of concerto)
# https://stackoverflow.com/a/48782486/1778068
RUN echo exit 0 >/usr/sbin/policy-rc.d

RUN echo "deb http://builder buster main" >>/etc/apt/sources.list
RUN apt update && apt install -y concerto-full
