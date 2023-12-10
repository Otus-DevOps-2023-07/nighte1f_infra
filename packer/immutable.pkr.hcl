variable "service_account_key_file" {
  type    = string
  default = null
}
variable "folder_id" {
  type    = string
  default = null
}
variable "source_image_family" {
  type    = string
  default = null
}
variable "ssh_username" {
  type    = string
  default = null
}


source "yandex" "ubuntu16" {
  service_account_key_file =  "${var.service_account_key_file}"
  folder_id = "${var.folder_id}"
  source_image_family = "${var.source_image_family}"
  image_name = "reddit-full-${formatdate("MM-DD-YYYY", timestamp())}"
  image_family = "reddit-full"
  ssh_username =  "${var.ssh_username}"
  platform_id = "standard-v1"
  use_ipv4_nat = true
}

build {
  sources = ["source.yandex.ubuntu16"]
  provisioner "shell" {
    inline = [
      "echo 'updating APT'",
      "sudo apt-get update -y",
      "sleep 10",
      "echo 'install ruby'",
      "sudo apt-get install -y ruby-full ruby-bundler build-essential",
      "sleep 10",
      "echo 'install mongodb'",
      "sudo apt-get install -y mongodb",
      "sudo systemctl enable mongodb",
      "sleep 10",
      "echo 'install git and app'",
      "sudo apt-get install git mc language-pack-ru -y",
      "mkdir -p /home/${var.ssh_username}/app ",
      "cd /home/${var.ssh_username}/app ",
      "git clone -b monolith https://github.com/express42/reddit.git",
      "cd reddit && bundle install",
      "echo 'configure autorun app'",
      "sudo echo '[Unit]                                                '  > /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo 'Description=App Reddit Up                             ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo '[Service]                                             ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo 'WorkingDirectory=/home/${var.ssh_username}/app/reddit ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo 'ExecStart=/usr/local/bin/puma                         ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo '[Install]                                             ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo echo 'WantedBy=multi-user.target                            ' >> /home/${var.ssh_username}/app/app-reddit.service ",
      "sudo systemctl enable                                                 /home/${var.ssh_username}/app/app-reddit.service ",
    ]
  }
}
