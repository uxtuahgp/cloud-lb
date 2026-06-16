resource "yandex_vpc_network" "cloud_net" {
  name      = var.vpc_net_name
  folder_id = var.folder_id
}


resource "yandex_vpc_subnet" "public_sub" {
  name           = var.vpc_subnet_pub_name
  folder_id      = var.folder_id
  zone           = var.default_zone
  network_id     = yandex_vpc_network.cloud_net.id
  v4_cidr_blocks = var.public_cidr
}
/*

resource "yandex_vpc_subnet" "private_sub" {
  name           = var.vpc_subnet_pvt_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.cloud_net.id
  v4_cidr_blocks = var.private_cidr
  route_table_id = yandex_vpc_route_table.cloud_rt.id
}
*/

resource "yandex_vpc_route_table" "cloud_rt" {
  network_id     = yandex_vpc_network.cloud_net.id
  folder_id      = var.folder_id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_ip
  }
}


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

resource "yandex_resourcemanager_folder_iam_member" "iam-vpc-admin" {
  folder_id = var.folder_id
  role = "vpc.admin"
  member = "serviceAccount:${yandex_iam_service_account.my-iam-sa.id}"
}

resource "time_sleep" "wait_for_iam" {
  depends_on = [yandex_resourcemanager_folder_iam_member.iam-admin, yandex_resourcemanager_folder_iam_member.iam-vpc-admin ]

  create_duration = "60s"
  destroy_duration = "20s"
}



resource "yandex_compute_instance_group" "ig-lamp" {
  name               = "ig-lamp"
  depends_on         = [ time_sleep.wait_for_iam ]
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
        nat       = false
      }

      metadata = {
        serial-port-enable = var.vms_md.serial
        ssh-keys           = "core:${var.vms_md.key}"
        user-data   = <<EOF
    #cloud-config
      runcmd:
        - echo PGltZwogICAgc3JjPSJodHRwOi8vdXh0dWFoZ3AtMjAyNjA2MTMuc3RvcmFnZS55YW5kZXhjbG91ZC5uZXQvdHV4LXBpYy0yMDI2MDYxMy5qcGciCi8+Cg== |base64 -d > /var/www/html/index.html
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
    max_creating = 1
    max_expansion = 0
    max_deleting = 2
  }
  health_check {
    timeout          = 5
    interval         = 10
    healthy_threshold  = 2
    unhealthy_threshold = 3
    http_options {
      port = 80
      path = "/"
    }
  }
  load_balancer {

    target_group_name        = "web-tg"
    target_group_description = "Target group for lamp instances"
  }
/*  health_check {
      name                    = "http-hc"
      interval                = 10
      timeout                 = 5
      unhealthy_threshold     = 2
      healthy_threshold       = 2
      http_options {
        port = 80
        path = "/"
      }
    }
*/
}

resource "yandex_lb_network_load_balancer" "my-nlb" {
  name = "my-nlb"
  listener {
    name = "nlb-listener"
    port = 80
  }
  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-lamp.load_balancer.0.target_group_id
    healthcheck {
      name = "http"
      unhealthy_threshold = 3
      healthy_threshold = 2
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
