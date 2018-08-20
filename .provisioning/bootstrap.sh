#!/bin/sh

# bootstrap.sh - one-time initialization of homebrew+ansible environment on OS X

# Install xcode
sudo xcode-select --install || true

# Install Homebrew

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew doctor

# Install Ansible

brew install ansible

# You should now be ready to run ansible locally.
