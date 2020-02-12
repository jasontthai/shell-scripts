#!/bin/bash

# Debian-based VPS Setup Script by Jason Thai
# Initial Feb 2020

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#    Debian-based VPS Setup Script    #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'

echo -e
date

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# override locale to eliminate parsing errors (i.e. using commas a delimiters rather than periods)
export LC_ALL=C

cancel() {
  echo -e
  echo -e " Aborted..."
  exit
}

trap cancel SIGINT

while getopts 'mh' flag; do
  case "${flag}" in
  m) MANUAL="True" ;;
  h) HELP="True" ;;
  *) exit 1 ;;
  esac
done

if [[ ! -z $HELP ]]; then
  echo -e
  echo -e "Usage: ./setup.sh [-mh]"
  echo -e
  echo -e "Flags:"
  echo -e "       -m : run setup script manually with prompt"
  echo -e "       -h : prints this lovely message, then exits"
  exit 0
fi

echo -e 'Updating system...'
apt-get update -y >/dev/null && apt-get upgrade -y >/dev/null

# Install basic packages
echo -e
echo -e 'Installing Basic Packages: sudo ufw fail2ban htop curl apache2 python-pip'
apt-get -y install sudo ufw fail2ban htop curl apache2 python-pip >/dev/null

echo -e
DISABLE_ROOT="Y"
DISABLE_PASSWORD_AUTH="Y"
INSTALL_DOCKER="Y"
INSTALL_DOCKER_COMPOSE="Y"
TIMEZONE="America/Los_Angeles"
USERNAME=$(who mom likes | cut -d' ' -f1)
ADD_NEW_USER="Y"
if [ ! -z "$MANUAL" ]; then
    read -p 'Add Sudo User? [y/N]: ' ADD_NEW_USER
    read -p 'Disable Root Login? [y/N]: ' DISABLE_ROOT
    read -p 'Disable Password Authentication? [y/N]: ' DISABLE_PASSWORD_AUTH
    read -p 'Install Docker? [y/N]: ' INSTALL_DOCKER
    read -p 'Install Docker Compose? [y/N]: ' INSTALL_DOCKER_COMPOSE
    read -p 'Enter your TIMEZONE [Empty to skip]: ' TIMEZONE
    read -p 'Enter any other packages to be installed [Empty to skip]: ' packages
fi

if [[ "$ADD_NEW_USER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Setting sudo user...'
  read -rp 'Username: ' USERNAME
  echo -n 'Password: '
  read -rs password
  adduser --disabled-password --gecos "" $USERNAME
  echo "$USERNAME:$password" | sudo chpasswd

  echo -e
  echo -e 'Adding SSH Keys'
  while true; do
    read -rp 'Enter SSH Key [Empty to skip]: ' sshKey
    if [[ -z "$sshKey" ]]; then
      break
    fi
    if [[ ! -d '/home/$USERNAME/.ssh' ]]; then
      mkdir -p /home/$USERNAME/.ssh
    fi
    chmod 700 /home/$USERNAME/.ssh
    touch /home/$USERNAME/.ssh/authorized_keys
    echo -e "$sshKey" >>/home/$USERNAME/.ssh/authorized_keys
    chmod 600 /home/$USERNAME/.ssh
    echo -e 'Saved SSH Key\n'
  done
fi

if [[ "$DISABLE_ROOT" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Disabling Root Login...'
  sed -i '/PermitRootLogin yes/c\PermitRootLogin no' /etc/ssh/sshd_config
fi
if [[ "$DISABLE_PASSWORD_AUTH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Disabling Password Authentication...'
  sed -i '/PasswordAuthentication yes/c\PasswordAuthentication no' /etc/ssh/sshd_config
fi
systemctl restart sshd

if [[ -n $TIMEZONE ]]; then
  echo -e
  echo -e 'Setting Timezone...'
  timedatectl set-timezone $TIMEZONE
fi

# Install Docker
if [[ "$INSTALL_DOCKER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  if [[ -z "$(command -v docker)" ]]; then
    curl -fsSL https://get.docker.com -o get-docker.sh | bash
  fi
  usermod -aG docker $USERNAME
  echo -e "Docker Installed. Added $USERNAME to docker group"
fi
if [[ "$INSTALL_DOCKER_COMPOSE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  if [[ -z "$(echo command -v docker-compose)" ]]; then
    pip install docker-compose
  fi
  echo -e "Docker Compose Installed."
fi

if [[ -n $packages ]]; then
  echo -e
  echo -e "Installing $packages ..."
  apt-get -y install $packages >/dev/null
fi

# reset locale settings
unset LC_ALL

echo -e
echo -e 'Finished setup script.'
exit 0

