#!/bin/sh

# bootstrap.sh - one-time initialization of homebrew+ansible environment on OS X

# Install xcode
sudo xcode-select --install || true

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# you might need:
echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> $HOME/.zprofile
. $HOME/.zprofile

# check with
brew doctor

# Install Ansible
brew install ansible

# Make sure you are in .provisioning folder
cd .provisioning

# Install requirements from Ansible Galaxy
ansible-galaxy install -r requirements.yml  

# You should now be ready to run ansible locally.
