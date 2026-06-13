###cloud vars


variable "cloud_id" {
  type        = string
  description = "My cloud Id"
  default = "b1g8d1us93gouobagkui"
}

variable "folder_id" {
  type        = string
  description = "My folder Id"
  default = "b1gjfbcv5j7vudl3n81h"
}

variable "bucket_name" {
  type        = string
  description = "My bucket name"
  default     = "uxtuahgp-20260613"
}

variable "object_key" {
  type        = string
  description = "My picture object key"
  default     = "tux-pic-20260613.jpg"
}

variable "local_pic_filename" {
  type        = string
  description = "My picture local filename for upload"
  default     = "./tux.jpg"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = ""
}

variable "public_cidr" {
  type        = list(string)
  default     = ["192.168.10.0/24"]
  description = "public subnet cidr"
}

variable "vpc_net_name" {
  type        = string
  default     = "cloud-net"
  description = "VPC public network name"
}

variable "private_cidr" {
  type        = list(string)
  default     = ["192.168.20.0/24"]
  description = "private subnet cidr"
}

variable "nat_ip" {
  type        = string
  default     = "192.168.10.254"
  description = "NAT instance IP"
}

variable "vpc_subnet_pub_name" {
  type        = string
  default     = "public"
  description = "public subnet"
}

variable "vpc_subnet_pvt_name" {
  type        = string
  default     = "private"
  description = "private subnet"
}

variable "vms_resources" {
  type        = map
  default     = {
    pub = {
      cores         = 2
      memory        = 2
      fraction = 5
    }
    pvt = {
      cores         = 2
      memory        = 2
      fraction = 5
    }
  }
}

variable  "vms_md" {
  type       = map
  default    = {
    serial  = 1
    key     = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLFQBGmKA6PF2ywadndvwutcoG4Sq4p00vIE1ECxhx6quoPkQu35Pbfb/zc/lqKeWUnRw+OgS6IVxDAveZ1jZRc= alex@uxtu-note"
  }
}
