#!/bin/bash

sudo sed -i -e 's/^bind_ip/#bind_ip/;' /etc/mongodb.conf
sudo service mongodb restart
sudo apt remove python3.5-minimal -y
sudo apt install python -y
