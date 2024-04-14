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
  image_name = "reddit-db-base-${formatdate("MM-DD-YYYY", timestamp())}"
  image_family = "reddit-db-base"
  ssh_username =  "${var.ssh_username}"
  platform_id = "standard-v1"
  use_ipv4_nat = "${var.ipv4_nat}"
}

build {
  sources = ["source.yandex.ubuntu16"]
  provisioner "shell" {
    inline = [
      "echo 'updating APT'",
      "sleep 20",
      "sudo add-apt-repository -y ppa:jblgf0/python",
      "sleep 20",
      "sudo apt-get update",
      "sleep 30",
      "sudo apt-get install python3.6 -y",
      "python3 --version",
      "sudo apt-get install python -y",
      "python --version",
    ]
  }
  provisioner "ansible" {
    playbook_file = "ansible/playbooks/packer_db_old.yml"
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/usr/bin/python2.7"]
    use_proxy = false
  }
}
