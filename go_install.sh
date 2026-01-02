#!/bin/bash

set -ex

VERSION_NUMBER=1.24.0
PACKAGE_NAME=go$VERSION_NUMBER.linux-amd64.tar.gz
# Install Go
wget https://go.dev/dl/$PACKAGE_NAME
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $PACKAGE_NAME && sudo rm $PACKAGE_NAME
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

set +ex
