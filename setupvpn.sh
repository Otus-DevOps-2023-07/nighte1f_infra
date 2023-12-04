#!/bin/bash

echo "deb http://repo.pritunl.com/stable/apt focal main" | sudo tee /etc/apt/so>
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D58>
curl https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc >
curl -fsSL https://pgp.mongodb.com/server-7.0.asc |    sudo gpg -o /usr/share/k>
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.g>
apt update
apt -y install wireguard wireguard-tools
ufw disable
apt -y install pritunl mongodb-org
systemctl enable mongod.service pritunl
systemctl start mongod.service pritunl
