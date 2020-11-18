#!/bin/bash
GO_VER="1.15.5"
GO_SHA="9a58494e8da722c3aef248c9227b0e9c528c7318309827780f16220998180a0d"

# Run unattended
export DEBIAN_FRONTEND=noninteractive

# Customize .profile
if ! grep --quiet "# bootstrapped section" /home/vagrant/.profile; then
  sudo echo "# bootstrapped section
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/vagrant
" >> /home/vagrant/.profile
  source /home/vagrant/.profile
fi

# Update system, confirm necessary tools
sudo apt-get update &&
  sudo apt-get upgrade --yes &&
  sudo apt-get install --yes git coreutils tar wget

# Install Go
GO_URL="https://golang.org/dl/"
GO_TAR="go$GO_VER.linux-amd64.tar.gz"
sudo wget --quiet $GO_URL$GO_TAR
printf "$GO_SHA $GO_TAR" | sha256sum --check |& grep "OK$"
if [ $? -ne 0 ]; then
  echo "Download or verification of $GO_URL$GO_TAR with checksum $GO_SHA failed, aborting."
  exit 1
fi
sudo rm --recursive --force /usr/local/go &&
  sudo tar --directory=/usr/local --extract --gzip --file=$GO_TAR &&
  sudo rm $GO_TAR
go version |& grep "^go version go"
if [ $? -ne 0 ]; then
  echo "Installation of $GO_TAR failed, aborting."
  exit 1
fi
