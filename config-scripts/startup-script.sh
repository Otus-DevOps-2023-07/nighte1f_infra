#!/bin/bash
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential
sudo apt install mongodb -y
sudo systemctl start mongodb
sudo systemctl enable mongodb
sudo apt install git -y
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
