#!/bin/sh

# bootstrap.sh - one-time initialization of homebrew+ansible environment on OS X

# Install xcode
sudo xcode-select --install || true

# Install Homebrew

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew doctor

# Install Ansible

brew install ansible

# Create a local ansible-config
sudo mkdir -p /etc/ansible
curl https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg | sudo tee /etc/ansible/ansible.cfg > /dev/null

# Add localhost with connection local to ansible's hosts file.
echo 'localhost ansible_connection=local' | sudo tee /etc/ansible/hosts >> /dev/null

# We're using a custom ansible role (which only contains a module).
ansible-galaxy install -r ~/.provisioning/requirements.yml

# You should now be ready to run ansible locally.
