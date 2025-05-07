${base_config}

# Hostname specifico
hostname: ${hostname}

# Chiave SSH
users:
  - name: root
    ssh_authorized_keys:
      - ${ssh_pub_key}

# Configurazioni personalizzate
${custom_config}