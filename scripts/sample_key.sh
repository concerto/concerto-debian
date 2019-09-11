#!/bin/bash
export GPG_TTY=$(tty)
cat <<-EOF | gpg --batch --generate-key
%no-ask-passphrase
%no-protection
Key-Type: default
Subkey-Type: default
Name-Real: sample
Name-Email: sample@example.com
%commit
EOF

gpg --armor --output /concerto-debian/concerto_deb_public.key --export sample@example.com 
