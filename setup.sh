#!/bin/bash

# VPS Setup Script by Jason Thai
# Initial Feb 2020

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#           VPS Setup Script          #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'

echo -e
date

# override locale to eliminate parsing errors (i.e. using commas a delimiters rather than periods)
export LC_ALL=C

cancel() {
  echo -e
  echo -e " Aborted..."
  exit
}

init() {
  # check release
  if [ -f /etc/redhat-release ]; then
      RELEASE="centos"
  elif cat /etc/issue | grep -Eqi "debian"; then
      RELEASE="debian"
  elif cat /etc/issue | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
      RELEASE="centos"
  elif cat /proc/version | grep -Eqi "debian"; then
      RELEASE="debian"
  elif cat /proc/version | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
      RELEASE="centos"
  fi
}

trap cancel SIGINT

while getopts 'ah' flag; do
  case "${flag}" in
  a) AUTO="True" ;;
  h) HELP="True" ;;
  *) exit 1 ;;
  esac
done

if [[ -n $HELP ]]; then
  echo -e
  echo -e "Usage: ./setup.sh [-mh]"
  echo -e "       curl -sL json.id/setup.sh | sudo bash"
  echo -e "       curl -sL json.id/setup.sh | sudo bash -s --{ah}"
  echo -e
  echo -e "Flags:"
  echo -e "       -a : run setup script automatically"
  echo -e "       -h : prints this lovely message, then exits"
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

init

echo -e 'Updating system...'
if [[ "$RELEASE" == "centos" ]]; then
  yum -y -q update
else
  apt-get update -y -qq && apt-get upgrade -y -qq
fi

# Install basic packages
echo -e
echo -e 'Installing Basic Packages: sudo ufw fail2ban htop curl apache2 tmux'
if [[ "$RELEASE" == "centos" ]]; then
  yum -y -q install sudo ufw ufw fail2ban htop curl apache2 tmux
else
  apt-get -y -qq install sudo ufw fail2ban htop curl apache2 tmux
fi

echo -e
DISABLE_ROOT="N"
DISABLE_PASSWORD_AUTH="N"
INSTALL_DOCKER="Y"
INSTALL_DOCKER_COMPOSE="Y"
TIMEZONE="America/Los_Angeles"
USERNAME="$(echo $SUDO_USER)"
ADD_NEW_USER="Y"
if [ -z "$AUTO" ]; then
    read < /dev/tty -p 'Add Sudo User? [y/N]: ' ADD_NEW_USER
    read < /dev/tty -p 'Disable Root Login? [y/N]: ' DISABLE_ROOT
    read < /dev/tty -p 'Disable Password Authentication? [y/N]: ' DISABLE_PASSWORD_AUTH
    read < /dev/tty -p 'Install Docker? [y/N]: ' INSTALL_DOCKER
    read < /dev/tty -p 'Install Docker Compose? [y/N]: ' INSTALL_DOCKER_COMPOSE
    read < /dev/tty -p 'Enter your TIMEZONE [Empty to skip]: ' TIMEZONE
    read < /dev/tty -p 'Enter any other packages to be installed [Empty to skip]: ' packages
fi

if [[ "$ADD_NEW_USER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Setting sudo user...'
  read < /dev/tty -rp 'Username: ' USERNAME
  echo -n 'Password: '
  read < /dev/tty -rs password
  if [[ "$RELEASE" == "centos" ]]; then
    adduser $USERNAME
    usermod -aG wheel $USERNAME
  else
    adduser --disabled-password --gecos "" $USERNAME
    usermod -aG sudo $USERNAME
  fi
  echo "$USERNAME:$password" | sudo chpasswd

  echo -e
  echo -e 'Adding SSH Keys'
  while true; do
    read < /dev/tty -rp 'Enter SSH Key [Empty to skip]: ' sshKey
    if [[ -z "$sshKey" ]]; then
      break
    fi
    if [[ ! -d '/home/$USERNAME/.ssh' ]]; then
      mkdir -p /home/$USERNAME/.ssh
    fi
    touch /home/$USERNAME/.ssh/authorized_keys
    echo -e "$sshKey" >>/home/$USERNAME/.ssh/authorized_keys
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
    curl -fsSL https://get.docker.com | bash
  fi
  usermod -aG docker $USERNAME
  echo -e "Docker Installed. Added $USERNAME to docker group"
fi
if [[ "$INSTALL_DOCKER_COMPOSE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  if [[ -z "$(command -v docker-compose)" ]]; then
    curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi
  echo -e "Docker Compose Installed."
fi

if [[ -n $packages ]]; then
  echo -e
  echo -e "Installing $packages ..."
  if [[ "$RELEASE" == "centos" ]]; then
    yum -y -q install $packages
  else
    apt-get -y -qq install $packages
  fi
fi

# reset locale settings
unset LC_ALL

echo -e
echo -e 'Finished setup script.'
exit 0

