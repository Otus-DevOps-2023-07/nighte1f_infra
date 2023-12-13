#!/bin/bash

apt-get update
echo "sleep 3m for install updates"; sleep 3m; echo "start install ruby"
apt-get install -y ruby-full ruby-bundler build-essential
