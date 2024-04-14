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
    ```
	packer validate -var-file=variables.pkr.hcl app.pkr.hcl
    packer validate -var-file=variables.pkr.hcl db.pkr.hcl
    packer build -var-file=variables.pkr.hcl app.pkr.hcl
    packer build -var-file=variables.pkr.hcl db.pkr.hcl
	```
- Конфигурация разбита на отдельные файлы
    для проверки заходим на хосты и проверяем наличии руби и монгодб
	```
	ssh -i ~/.ssh/appuser ubuntu@'hostip'
	ruby -v
	systemctl status mongodb
	```

- Созданы модули
    В каждый модуль добавлен config.tf с провайдером яндекса
- Удалены конфигурации из основного каталога
- Отформатированы конфигурации
	```
	terraform fmt
	```

- Создан S3 бакет для хранения состояния
	Создаём ключи
	```
	yc iam access-key create --service-account-name terraform-sa
	```
	Добавляем переменные
	```
	variable access_key {
	description = "key id"
	}
	variable secret_key {
	  description = "secret key"
	}
	variable bucket_name {
	  description = "bucket name"
	}
	```

	В каталоге terraform создаем конфиг бакета storage-backet.tf
	```
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
	```

	Запускаем его создание
	```
	terraform apply
	```

- В каждой из сред создаем backend.tf для указания бекэнда
	```
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
	```
	Запускаем
	```
	terraform init -backend-config="access_key='KEY'" -backend-config="secret_key='SECRET'"
	```
	Переносим кофиги и повторно запускаем
	```
	terraform init -backend-config="access_key='KEY'" -backend-config="secret_key='SECRET'" -reconfigure
	```
	Блокировки работают

- Создаем деплой приложения
	В каждом из модулей создать каталог files где будут хранится наши конфиги и скрипты
	Создаем темплейт puma.service.tmpl конфига для нашего приложения добавив адресс для подключения к базе
	```
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
	```

	Теперь модифицируем main.tf добавив провижионеры
	```
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
	```

	 Описываем переменную db_ip
	```
	variable db_ip {
		description = "database IP"
	}
	```
	Добавляем в main.tf
	```
	module "app" {
	  source          = "../modules/app"
	  public_key_path = var.public_key_path
	  private_key_path = var.private_key_path
	  app_disk_image  = var.app_disk_image
	  subnet_id       = var.subnet_id
	  db_ip           = module.db.db_internal_ip
	}
	```

	Добавляем в db/outputs.ff вывод внутреннего ip
	```
	output "db_internal_ip" {
	  value = yandex_compute_instance.db.network_interface.0.ip_address
	}
	```

	Добавляем провижионеры в наш файл в db main.tf
	```
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
	  ```

- Для запуска проекта:
	Создаем бакет
	В каталоге terraform
		```
		terraform apply
		```
	В необходимой среде
		```
		terraform apply
		```

- Проверка работоспособности
	'полученный внешний адрес приложения':9292


# Homework 8
- Создана новая ветка
- Установлен ансибл
- Поднята инфра stage
- Созданы inventory
- Создан файл конфига ансибл
- Создан плейбук
- С серверов инфры удалены пакеты с питоном 3.5 и установлены с питоном 2.7
	для этого в деплои модулей добавлено следующее
		```
		sudo apt remove python3.5-minimal -y
		sudo install python
		```

- Создан inventory.json
	```
	{
		"_meta": {
			"hostvars": {}
		},
		"app": {
			"hosts": ["51.250.8.20"],
			"vars": {
				"ansible_user": "ubuntu",
				"ansible_private_key_file": "~/.ssh/ubuntu"
			}
		},
		"db": {
			"hosts": ["51.250.89.119"],
			"vars": {
				"ansible_user": "ubuntu",
				"ansible_private_key_file": "~/.ssh/ubuntu"
			}
		}
	}
	```

- Создан скрипт, который парсит вывод yc compute instance list
- Изменён ansible.cfg
	```
	inventory = ./dynamicinv.sh
	```

- Для проверки задания:
	```
	ansible all -m ping
	```

# Homework 9
- Создана новая ветка
- Закомменчен код для провижнов в терраформе
- Протестированы один плейбук, один сценарий:

Плейбуки

Сценарий плейбука

Сценарий для MongoDB

Шаблон конфига MongoDB

Пробный, тестовый прогон
	```
	ansible-playbook reddit_app.yml --check
	ansible-playbook reddit_app.yml --check --limit db
	```
Определение переменных

Корректировка 2-х темплейтов для mongod и mongodb

Пробный прогон

Handlers

Добавлены handlers

Применим плейбук
	```
	ansible-playbook  reddit_app.yml  --limit db
	```
Настройка инстанса приложения

Unit для приложения

Добавлен шаблон для приложения

Настройка инстанса приложения
	```
	ansible-playbook reddit_app.yml --check --limit db --tags db-tag
	ansible-playbook reddit_app.yml --check --limit app --tags app-tag
	ansible-playbook reddit_app.yml --limit app --tags app-tag
	```

Выполняем деплой
	```
	ansible-playbook reddit_app.yml --check --limit app --tags deploy-tag
	ansible-playbook reddit_app.yml --limit app --tags deploy-tag
	```

Проверяем работу приложения

- Протестированы один плейбук, много сценариев

Пересоздадим инфраструктуру

Проверим работу сценариев
	```
	ansible-playbook reddit_app2.yml --tags db-tag --check
	ansible-playbook reddit_app2.yml --tags db-tag
	ansible-playbook reddit_app2.yml --tags app-tag --check
	ansible-playbook reddit_app2.yml --tags app-tag
	```

Сценарий для деплоя
	```
	ansible-playbook reddit_app2.yml --tags app-tag
	```

Проверка сценария
	```
	ansible-playbook reddit_app2.yml --tags deploy-tag --check
	```

- Несколько плейбуков
db.yml
app.yml
deploy.yml
site.yml
Проверка результата
	```
	ansible-playbook site.yml --check
	ansible-playbook site.yml
	```

- Созданы новые образы при помощи пакера
Изменен провижн образов Packer на Ansible-плейбуки
	```
	ansible-playbook --check packer_db.yml
	ansible-playbook --check packer_app.yml
	```

Интегрируем Ansible в Packer

Проверяем образы
	```
	packer validate -var-file=variables.pkr.hcl db.pkr.hcl
	packer validate -var-file=variables.pkr.hcl app.pkr.hcl
	```

Для настройки плагина понадобилось добавить в config.hcl информацию о плагине ансибла
	```
	packer init -var-file=variables.pkr.hcl app.pkr.hcl
	packer validate -var-file=packer/variables.pkr.hcl packer/db.pkr.hcl
	packer validate -var-file=packer/variables.pkr.hcl packer/app.pkr.hcl
	```

Так же ансибл ругался на версию питона на хосте, через шелл был установлен питон 2 и указано его использование
	```
	extra_arguments = [
		"--extra-vars",
		"ansible_python_interpreter=/usr/bin/python2.7"]
	```

Помогло но не совсем, поэтому на своей вм был удалён ансибл и установлен через apt, после этого образ стал корректно работать
	```
	packer build -var-file=packer/variables.pkr.hcl packer/db.pkr.hcl
	packer build -var-file=packer/variables.pkr.hcl packer/app.pkr.hcl
	yc compute image list
	```

Меняем id образов в переменных терраформа и запускаем создание инфры
	```
	terraform/stage> terraform destroy
	terraform/stage> terraform apply -auto-approve
	```

Проверяем работу плейбука
	```
	ansible-playbook site.yml --check
	```

Выдает ошибку, т.к. нет сервиса пумы, но при применении плейбука всё отрабатывает
	```
	ansible-playbook site.yml
	```

- Проверяем работу
'внешний адрес':9292


# Homework 10
- Создана новая ветка
- Созданы роли
	```
	ansible-galaxy init app
	ansible-galaxy init db
	```

- Созданы и сконфигурированы два окружения
	```
	ansible-playbook -i environments/prod/inventory deploy.yml
	```

Дефолтное окружение задано в ansible.cfg

- Определены групповые переменные
- Организован отдельный каталог для плейбуков, весь "мусор" разнесен по каталогам
- Организована комьюнити-роль nginx
	```
	ansible-galaxy install -r environments/stage/requirements.yml
	```

- Изучена возможность открития портов в группах безопасности (по дефолту у нас сейчас всё открыто)
	```
	resource "yandex_vpc_security_group_rule" "rule1" {
	  security_group_binding = <идентификатор_группы_безопасности>
	  direction              = "ingress"
	  description            = "<описание_правила>"
	  v4_cidr_blocks         = ["10.0.1.0/24", "10.0.2.0/24"]
	  port                   = 8080
	  protocol               = "TCP"
	}
	```

- Настроен ansible-vault для окружений
	```
	touch vault.key
	vim ansible.cfg
		vault_password_file = vault.key
	```

- Добавлены креды и плейбук для создания юзеров
- С помощью ansible.vault креды зашифрованы
	```
	ansible-vault encrypt environments/prod/credentials.yml
	ansible-vault encrypt environments/stage/credentials.yml
	ansible-vault edit <file> - редактирование
	ansible-vault decrypt <file> - расшифровка
	```

- Добавлен вызов плейбука на создание пользователей в site.yml


# Homework 11
- Создана новая ветка
- Установлен вагрант через apt install
- Установлен virtual box
Добавлен конфиг для сети 10.0 в /etc/vbox/networks.config

- В Vagrantfile добавлена строка для скачивания образов
	```
	ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

	vagrant init
	vagrant up
	vagrant box list
	vagrant status
	vagrant ssh 'server_name'
	vagrant destroy -f
	```

- Добавлена роль ансибла
	```
	vagrant provision 'server_name'
	```

- Создан плейбук с установкой питона 2 (ЗЫ у меня такой ошибки не выдавало)
- Доработаны роли
- Для корректной работы оператива на вм увеличина до 2гб
- Просмотрен инвентори вагранта
	```
	cat .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory
	```

- Добавлена extra_vars для nginx
	```
	"nginx_sites" => { "default" => [ "listen 80", "server_name reddit", "location / { proxy_pass http://127.0.0.1:9292; }" ]  }
	```

- Установлен molecule. Для ансибла 6.7 (core 2.13.13). molecule_vagrant 2.0.0
	```
	python3 -m pip install --user molecule==3.5.1

	molecule init scenario default -r db -d vagrant
	molecule create
	molecule list
	molecule login -h instance
	```

- Для моей версии molecule меняем плейбук converge.yml и прогоняем тесты
	```
	molecule converge
	molecule verify
	```

- Добавлена проверка порта
	```
	def test_mongo_port(host):
    assert host.socket('tcp://0.0.0.0:27017').is_listening
	```
- Скопированы конфиги и измененый плейбуки пакера (добавлены роли)
- Изменены конфиги пакера
