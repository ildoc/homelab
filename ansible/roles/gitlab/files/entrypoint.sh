#!/bin/bash

# Sistema i permessi delle chiavi SSH
chmod 600 /etc/gitlab/ssh_host_*_key || true
chown root:root /etc/gitlab/ssh_host_*_key || true

# Avvia GitLab normalmente
exec /assets/init-container
