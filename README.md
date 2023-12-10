# nighte1f_infra
nighte1f Infra repository

HOMEWORK 3

3.1
use -J ssh option:
ssh -i ~/.ssh/appuser -J appuser@62.84.127.189 appuser@10.128.0.33

3.2
Add local ssh config file ~/.ssh/config
Host someinternalhost
    HostName 10.128.0.33
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump appuser@bastion

Host bastion
    HostName 62.84.127.189
    User appuser


3.3
bastion_IP = 62.84.127.189
someinternalhost_IP = 10.128.0.33


###########################################

Homework 4

Create VM with startup script

testapp_IP = 51.250.73.26
testapp_port = 9292


Commant to create VM:
yc compute instance create \
   --name reddit-app \
   --hostname reddit-app \
   --core-fraction=20 \
   --memory=4 \
   --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
   --metadata-from-file='user-data=startup.yaml'


###########################################

# Homework 5

Created service account for YC
Created image with using packer
Created VM with this image

# PROBLEMS:
yandex: Error creating network ... etc
solution: deletion  all network profiles

when install packages:
yandex.ubuntu16: E: Could not get lock ... etc
yandex.ubuntu16: E: Unable to acquire the dpkg frontend lock ... etc
solution: need add "sleep" after commands

# Checking and running the configuration

packer validate -var-file=variables.json.example ubuntu16.json
packer build -var-file=variables.json.example ubuntu16.json

packer validate -var-file=variables.pkr.hcl.examples ubuntu16.pkr.hcl
packer build -var-file=variables.pkr.hcl.examples ubuntu16.pkr.hcl
