#!/bin/sh
sudo apt-get update && apt-get -qq install python3 -y && apt-get upgrade python3
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip git
sudo pip3 install --upgrade pip
sudo pip3 install --upgrade ansible
echo \"Running Ansible in `pwd`\"

