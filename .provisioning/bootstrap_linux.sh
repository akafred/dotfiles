#!/bin/sh

# bootstrap.sh - one-time initialization of linuxbrew+ansible environment on Linux (RHEL)


# Install Linuxbrew

sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

# Install Ansible

su -
yum install git ansible
exit

@# Install requirements froom Ansible Galaxy
ansible-galaxy install -r requirements.yml

# You should now be ready to run ansible locally.
