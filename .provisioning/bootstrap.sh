#!/bin/sh

# bootstrap.sh - one-time initialization of homebrew+ansible environment on OS X

# Install xcode
sudo xcode-select --install

# Install Homebrew

ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
brew doctor

# Install Ansible

brew install ansible

# Create a local ansible-config without /usr/share/ansible as library-dir
sudo mkdir -p /etc/ansible
curl https://raw.github.com/ansible/ansible/devel/examples/ansible.cfg | grep -v 'library        = /usr/share/ansible' | sudo tee .ansible.cfg > /dev/null

# Add localhost with connection local to ansible's hosts file.
echo 'localhost ansible_connection=local' | sudo tee /etc/ansible/hosts >> /dev/null

# You should now be ready to run ansible locally.