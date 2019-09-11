FROM ubuntu:xenial
EXPOSE 80

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y -qq curl dialog gnupg2 nmap tzdata vim wget

# prepare image for installing any service (in case we want to test installation of concerto)
# https://stackoverflow.com/a/48782486/1778068
RUN echo exit 0 >/usr/sbin/policy-rc.d

COPY scripts/test_install.sh /
RUN chmod +x /test_install.sh
CMD /test_install.sh
