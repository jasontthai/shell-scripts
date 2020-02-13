# shell-scripts
A collection of shell scripts

## How to Run
```
curl -L json.id/setup.sh | sudo bash
```

## Example Output
```shell
curl -sL json.id/setup.sh | sudo bash
# ## ## ## ## ## ## ## ## ## ## ## ## #
#    Debian-based VPS Setup Script    #
# ## ## ## ## ## ## ## ## ## ## ## ## #

Wed 12 Feb 2020 03:56:01 PM PST
Updating system...

Installing Basic Packages: sudo ufw fail2ban htop curl apache2

Add Sudo User? [y/N]: y
Disable Root Login? [y/N]: y
Disable Password Authentication? [y/N]: y
Install Docker? [y/N]: y
Install Docker Compose? [y/N]: y
Enter your TIMEZONE [Empty to skip]:
Enter any other packages to be installed [Empty to skip]:

Setting sudo user...
Username: testuser
Password:

Adding SSH Keys
Enter SSH Key [Empty to skip]:

Disabling Root Login...

Disabling Password Authentication...

Docker Installed. Added testuser to docker group

Docker Compose Installed.

Finished setup script.
```
