resource "yandex_vpc_network" "cloud_net" {
  name = var.vpc_net_name
}


resource "yandex_vpc_subnet" "public_sub" {
  name           = var.vpc_subnet_pub_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.cloud_net.id
  v4_cidr_blocks = var.public_cidr
}


resource "yandex_vpc_subnet" "private_sub" {
  name           = var.vpc_subnet_pvt_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.cloud_net.id
  v4_cidr_blocks = var.private_cidr
  route_table_id = yandex_vpc_route_table.cloud_rt.id
}


/*
data "yandex_compute_image" "ubuntu" {
  family = var.vm_family
}
*/

resource "yandex_storage_bucket" "my-bucket" {
  bucket    = var.bucket_name
  folder_id = var.folder_id
}

resource "yandex_storage_object" "upload-pic" {
  bucket = var.bucket_name
  key = var.object_key
  source = var.local_pic_filename
  content_type = "image/jpeg"
  acl    = "public-read"
  depends_on = [yandex_storage_bucket.my-bucket]
}


resource "yandex_iam_service_account" "my-iam-sa" {
  name        = "my-iam-sa"
  description = "IAM service account"
  folder_id   = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "iam-admin" {
  folder_id = var.folder_id
  role = "admin"
  member = "serviceAccount:${yandex_iam_service_account.my-iam-sa.id}"
}


resource "yandex_compute_instance_group" "ig-lamp" {
  name               = "ig-lamp"
  service_account_id = yandex_iam_service_account.my-iam-sa.id
  folder_id = var.folder_id
    instance_template {
    platform_id = var.vm_platform
    resources {
      cores         = var.vms_resources.pub.cores
      memory        = var.vms_resources.pub.memory
      core_fraction = var.vms_resources.pub.fraction
   }
    boot_disk {
      initialize_params {
        image_id = var.ig_lamp_image_id
      }
    }
    network_interface {
      subnet_ids = [ yandex_vpc_subnet.public_sub.id ]
      nat       = true
    }
    metadata = {
      serial-port-enable = var.vms_md.serial
      ssh-keys           = "core:${var.vms_md.key}"
      user-data = <<EOF
#cloud-config
write-files:
  - path: /var/www/html/index.html
    permissions: "0644"
    content: |
    <html> <body> <img src=http://uxtuahgp-20260613.storage.yandexcloud.net/tux-pic-20260613.jpg> </body> </html>
EOF

    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = [var.default_zone]
  }
  deploy_policy {
    max_unavailable = 2
    max_creating = 3
    max_expansion = 3
    max_deleting = 3
  }
}










/*
resource "yandex_compute_instance" "nat" {
  name            = "nat"
  hostname        = "nat"
  platform_id = var.vm_platform
  resources {
    cores         = var.vms_resources.pub.cores
    memory        = var.vms_resources.pub.memory
    core_fraction = var.vms_resources.pub.fraction
 }
  boot_disk {
    initialize_params {
      image_id = var.vm_nat_image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_sub.id
    nat        = true
    ip_address = var.nat_ip
  }


  metadata = {
    serial-port-enable = var.vms_md.serial
    ssh-keys           = "core:${var.vms_md.key}"
  }
}
*/

resource "yandex_vpc_route_table" "cloud_rt" {
  network_id = yandex_vpc_network.cloud_net.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_ip
  }
}

/*
resource "yandex_compute_instance" "pub-01" {
  name            = "pub-01"
  hostname        = "pub-01"
  platform_id = var.vm_platform
  resources {
    cores         = var.vms_resources.pub.cores
    memory        = var.vms_resources.pub.memory
    core_fraction = var.vms_resources.pub.fraction
 }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_sub.id
    nat       = true
  }


  metadata = {
    serial-port-enable = var.vms_md.serial
    ssh-keys           = "core:${var.vms_md.key}"
  }
}


resource "yandex_compute_instance" "pvt-01" {
  name            = "pvt-01"
  hostname        = "pvt-01"
  platform_id = var.vm_platform
  resources {
    cores         = var.vms_resources.pvt.cores
    memory        = var.vms_resources.pvt.memory
    core_fraction = var.vms_resources.pvt.fraction
 }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }

  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private_sub.id
    nat       = false
  }


  metadata = {
    serial-port-enable = var.vms_md.serial
    ssh-keys           = "core:${var.vms_md.key}"
  }
}
 */
