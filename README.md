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

- Created service account for YC
- Created image with using packer
- Created VM with this image

# PROBLEMS:
- yandex: Error creating network

solution: deletion  all network profiles

when install packages:
- yandex.ubuntu16: E: Could not get lock
- yandex.ubuntu16: E: Unable to acquire the dpkg frontend lock

solution: need add "sleep" after commands

# Checking and running the configuration

- packer validate -var-file=variables.json.example ubuntu16.json
- packer build -var-file=variables.json.example ubuntu16.json

- packer validate -var-file=variables.pkr.hcl.examples ubuntu16.pkr.hcl
- packer build -var-file=variables.pkr.hcl.examples ubuntu16.pkr.hcl

# Homework 6
- Created config file for terraform
- Created file with variables
- Created load-balancer config with "count" variable

# running configuration
- terraform fmt
- terraform plan
- terraform apply


# Homework 7
- Создана новая ветка
- lb.tf перемещен в files/
- Правка outputs.tf
- При создании сети пришлось удалить дефолтную сеть, т.к. действует лимит (написано обращение в тп)
- Подготовлены образы через пакер
    packer validate -var-file=variables.pkr.hcl app.pkr.hcl
    packer validate -var-file=variables.pkr.hcl db.pkr.hcl
    packer build -var-file=variables.pkr.hcl app.pkr.hcl
    packer build -var-file=variables.pkr.hcl db.pkr.hcl
- Конфигурация разбита на отдельные файлы
    для проверки заходим на хосты и проверяем наличии руби и монгодб
	ssh -i ~/.ssh/appuser ubuntu@'hostip'
	ruby -v
	systemctl status mongodb

- Созданы модули
    В каждый модуль добавлен config.tf с провайдером яндекса
- Удалены конфигурации из основного каталога
- Отформатированы конфигурации
	terraform fmt

Создан S3 бакет для хранения состояния
	Создаём ключи
	yc iam access-key create --service-account-name terraform-sa
	Добавляем переменные
	variable access_key {
	description = "key id"
	}
	variable secret_key {
	  description = "secret key"
	}
	variable bucket_name {
	  description = "bucket name"
	}

	В каталоге terraform создаем конфиг бакета storage-backet.tf
	provider "yandex" {
	  version                  = "~> 0.43"
	  service_account_key_file = var.service_account_key_file
	  cloud_id                 = var.cloud_id
	  folder_id                = var.folder_id
	  zone                     = var.zone
	}

	resource "yandex_storage_bucket" "terraform" {
	  bucket        = var.bucket_name
	  access_key    = var.access_key
	  secret_key    = var.secret_key
	  force_destroy = "true"
	}

	Запускаем его создание
	terraform apply

- В каждой из сред создаем backend.tf для указания бекэнда
	terraform {
	  backend "s3" {
		endpoint   = "storage.yandexcloud.net"
		bucket     = "backend-bucket"
		region     = "ru-central1"
		key        = "stage/terraform.tfstate"

		skip_region_validation      = true
		skip_credentials_validation = true
	   }
	}
	Запускаем
	terraform init -backend-config="access_key='KEY'" -backend-config="secret_key='SECRET'"
	Переносим кофиги и повторно запускаем
	terraform init -backend-config="access_key='KEY'" -backend-config="secret_key='SECRET'" -reconfigure
	Блокировки работают

- Создаем деплой приложения
	В каждом из модулей создать каталог files где будут хранится наши конфиги и скрипты
	Создаем темплейт puma.service.tmpl конфига для нашего приложения добавив адресс для подключения к базе
	[Unit]
	Description=Puma HTTP Server
	After=network.target

	[Service]
	Type=simple
	User=ubuntu
	Environment=DATABASE_URL=${db_ip}
	WorkingDirectory=/home/ubuntu/reddit
	ExecStart=/bin/bash -lc 'puma'
	Restart=always

	[Install]
	WantedBy=multi-user.target

	Теперь модифицируем main.tf добавив провижионеры
	 connection {
		type        = "ssh"
		host        = yandex_compute_instance.app.network_interface[0].nat_ip_address
		user        = "ubuntu"
		agent       = false
		private_key = file(var.private_key_path)
	  }
	 provisioner "file" {
		content     = templatefile("${path.module}/files/puma.service.tmpl", { db_ip = var.db_ip})
		destination = "/tmp/puma.service"
	  }

	 provisioner "remote-exec" {
		script = "${path.module}/files/deploy.sh"
	  }

	 Описываем переменную db_ip
	 variable db_ip {
	  description = "database IP"
	}
	Добавляем в main.tf
	module "app" {
	  source          = "../modules/app"
	  public_key_path = var.public_key_path
	  private_key_path = var.private_key_path
	  app_disk_image  = var.app_disk_image
	  subnet_id       = var.subnet_id
	  db_ip           = module.db.db_internal_ip
	}

	Добавляем в db/outputs.ff вывод внутреннего ip
	output "db_internal_ip" {
	  value = yandex_compute_instance.db.network_interface.0.ip_address
	}

	Добавляем провижионеры в наш файл в db main.tf
	connection {
		type        = "ssh"
		host        = yandex_compute_instance.db.network_interface[0].nat_ip_address
		user        = "ubuntu"
		agent       = false
		private_key = file(var.private_key)
	  }

	  provisioner "remote-exec" {
		script = "${path.module}/files/deploy.sh"
	  }

- Для запуска проекта:
	Создаем бакет
	В каталоге terraform
		terraform apply
	В необходимой среде
		terraform apply

- Проверка работоспособности
	'полученный внешний адрес приложения':9292
