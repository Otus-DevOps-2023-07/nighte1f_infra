#!/bin/bash

apt-get update
apt-get install mongodb -y
systemctl enable mongodb
