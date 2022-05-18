variable "prefix" {
  type = string
}

variable "location" {
  type    = string
  default = "eastasia"
}

variable "vm_usrname" {
  type    = string
  default = "vm-admin"
}

variable "vm_password" {
  type    = string
  default = "+123QWEasd"
}

variable "disk_size_gb" {
  type = number
}
