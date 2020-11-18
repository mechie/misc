#!/bin/bash

# Run unattended
export DEBIAN_FRONTEND=noninteractive

# Customize .profile
if ! grep --quiet "# bootstrapped section" /home/vagrant/.profile; then
  sudo echo "# bootstrapped section
" >> /home/vagrant/.profile
  source /home/vagrant/.profile
fi

# Update system, confirm necessary tools
sudo apt-get update &&
  sudo apt-get upgrade --yes &&
  sudo apt-get install --yes curl git

# Install Rust
su - vagrant --command "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
