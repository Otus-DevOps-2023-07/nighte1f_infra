packer {
  required_plugins {
    yandex = {
      version = ">= 1.1.2"
      source = "github.com/hashicorp/yandex"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}
