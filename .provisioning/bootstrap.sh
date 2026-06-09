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

# Install requirements from Ansible Galaxy (skipped if none are listed;
# community.general comes bundled with brew's ansible, see requirements.yml)
grep -qE '^\s*-\s*name:' requirements.yml && ansible-galaxy install -r requirements.yml --force

# You should now be ready to run ansible locally.
