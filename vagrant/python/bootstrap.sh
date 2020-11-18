#!/bin/bash
PY_VER="python3.8"

# Run unattended
export DEBIAN_FRONTEND=noninteractive

# Customize .profile
if ! grep -q "# bootstrapped section" /home/vagrant/.profile; then
  sudo echo "# bootstrapped section
alias python='$PY_VER'
alias py='python'
alias pip='py -m pip'
" >> /home/vagrant/.profile
  source /home/vagrant/.profile
fi

# Update system, confirm necessary tools
sudo apt-get update &&
  sudo apt-get upgrade -y &&
  sudo apt-get install -y git

# Install Python
sudo apt-get install -y $PY_VER python3-pip
$PY_VER -m pip install --upgrade pip setuptools wheel
