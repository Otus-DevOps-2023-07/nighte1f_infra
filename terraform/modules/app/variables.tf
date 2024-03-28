variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable "subnet_id" {
  description = "Subnet"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable db_ip {
  description = "database IP"
}
variable "private_key" {
  description = "Path to the private key used for ssh access for provisioning"
}
