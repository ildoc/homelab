#!/bin/bash
set -euo pipefail

# sshd rifiuta host key con permessi troppo aperti (es. 0755).
shopt -s nullglob
for key in /etc/gitlab/ssh_host_*_key; do
  chmod 600 "${key}"
  chown root:root "${key}"
done
for pub in /etc/gitlab/ssh_host_*_key.pub; do
  chmod 644 "${pub}"
done

exec /assets/init-container
