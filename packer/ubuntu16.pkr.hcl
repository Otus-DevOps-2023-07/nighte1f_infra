variable "service_account_key_file" {
  type    = string
  default = null
  }

variable folder_id {
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

variable "ipv4_nat" {
  type    = string
  default = null
}

source "yandex" "ubuntu16" {
  service_account_key_file = "${var.service_account_key_file}"
  folder_id = var.folder_id
  source_image_family = "${var.source_image_family}"
  image_name = "reddit-base-Q${formatdate("MM-DD-YYYY", timestamp())}"
  image_family = "reddit-base"
  ssh_username =  "${var.ssh_username}"
  platform_id = "standard-v1"
  use_ipv4_nat = "${var.ipv4_nat}"
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
    ]
  }
}
