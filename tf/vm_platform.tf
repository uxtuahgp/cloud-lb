
variable "vm_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "Image family"
}

variable "vm_nat_image_id" {
  type        = string
  default     = "fd80mrhj8fl2oe87o4e1"
  description = "NAT Image Id"
}


variable "vm_platform" {
  type        = string
  default     = "standard-v2"
  description = "VM Instance Platform ID "
}
