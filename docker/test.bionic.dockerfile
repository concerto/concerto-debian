FROM ubuntu:bionic
EXPOSE 80

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y dialog gnupg2 tzdata vim wget

# prepare image for installing any service (in case we want to test installation of concerto)
# https://stackoverflow.com/a/48782486/1778068
RUN echo exit 0 >/usr/sbin/policy-rc.d

RUN echo "deb http://builder bionic main" >>/etc/apt/sources.list

# 30 sec warmup for builder to start serving
# sleep to keep the container running
CMD sleep 30 && wget -O - http://builder/sample.key | apt-key add - && apt update && apt install -y concerto-full && sleep infinity
