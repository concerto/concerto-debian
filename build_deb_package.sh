#!/bin/bash

find ./debian -type d | xargs chmod 755
fakeroot dpkg-deb --build debian
mv debian.deb Concerto_0.1-1_all.deb
lintian DjangoApp_0.1-1_all.deb
