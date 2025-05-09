#!/bin/bash

# Script di inizializzazione per container LXC
set -e

# Imposta l'hostname
echo "${hostname}" > /etc/hostname
hostname "${hostname}"

# Aggiorna il sistema e installa pacchetti di base
apt-get update -y
apt-get upgrade -y

# Installa i pacchetti richiesti
apt-get install -y gnupg curl nano ca-certificates zsh git ${packages}

# Configura SSH e aggiungi la chiave pubblica
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "${ssh_pub_key}" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Crea l'utente se non esiste già
if ! id ${default_user} &>/dev/null; then
  useradd -m -s /bin/zsh ${default_user}
  echo "${default_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${default_user}
  chmod 440 /etc/sudoers.d/${default_user}
  
  # Configura SSH per l'utente
  mkdir -p /home/${default_user}/.ssh
  echo "${ssh_pub_key}" > /home/${default_user}/.ssh/authorized_keys
  chmod 700 /home/${default_user}/.ssh
  chmod 600 /home/${default_user}/.ssh/authorized_keys
  chown -R ${default_user}:${default_user} /home/${default_user}/.ssh
fi

# Installa oh-my-zsh per l'utente
mkdir -p /home/${default_user}/.zsh
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O /home/${default_user}/install_oh_my_zsh.sh
chmod +x /home/${default_user}/install_oh_my_zsh.sh
su - ${default_user} -c /home/${default_user}/install_oh_my_zsh.sh --unattended
rm /home/${default_user}/install_oh_my_zsh.sh
chown -R ${default_user}:${default_user} /home/${default_user}

# Imposta ZSH come shell predefinita per l'utente
chsh -s /bin/zsh ${default_user}

# Assicurati che l'utente abbia ZSH come shell nel passwd file
usermod -s /bin/zsh ${default_user}

# Esegui script personalizzati
%{ for script in custom_scripts ~}
echo "Esecuzione script personalizzato: ${script}"
${script}
%{ endfor ~}

# Assicurati che il servizio SSH sia abilitato e in esecuzione
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable ssh
  systemctl start ssh
fi

echo "Inizializzazione completata con successo!"
exit 0
