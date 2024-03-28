resource "yandex_lb_network_load_balancer" "reddit" {
  name = "lb-reddit"
  #deletion_protection = "false"
  listener {
    name = "reddit-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.redditgroup.id
    healthcheck {
      name = "reddit-hc"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}

resource "yandex_lb_target_group" "redditgroup" {
  name      = "lbrg"
  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      address   = target.value
      subnet_id = var.subnet_id
    }
  }
}
