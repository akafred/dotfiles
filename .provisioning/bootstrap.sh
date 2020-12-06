#!/bin/sh

# bootstrap.sh - one-time initialization of homebrew+ansible environment on OS X

# Install xcode
sudo xcode-select --install || true

# Install Homebrew

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew doctor

# Install Ansible

brew install ansible

# Install requirements froom Ansible Galaxy
ansible-galaxy install -r requirements.yml

# You should now be ready to run ansible locally.
