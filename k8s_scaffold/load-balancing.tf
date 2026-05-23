# Load Balancer - HTTP

resource "oci_network_load_balancer_backend_set" "worker_tcp_80" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_80"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_80" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_80.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_80"
  name                     = "worker-${each.key}_tcp_80"
  port                     = 30080 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_80
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_80" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_80.name
  name                     = "worker_tcp_80"
  network_load_balancer_id = var.load_balancer_id
  port                     = 80
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_80,
    oci_network_load_balancer_backend.worker_tcp_80
  ]
}


# Load Balancer - HTTPS

resource "oci_network_load_balancer_backend_set" "worker_tcp_443" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_443"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_443" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_443.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_443"
  name                     = "worker-${each.key}_tcp_443"
  port                     = 30443 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_443
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_443" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_443.name
  name                     = "worker_tcp_443"
  network_load_balancer_id = var.load_balancer_id
  port                     = 443
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_443,
    oci_network_load_balancer_backend.worker_tcp_443
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for ChirpStack-v3


# chirpstack-gateway-bridge-chirpstack-v3-proxied-udp-1700
resource "oci_network_load_balancer_backend_set" "worker_udp_1700" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_udp_1700"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "UDP"
    port     = 1700
    request_data = "UElORw==" # PING
    response_data = "UE9ORw==" # PONG
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_udp_1700" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_udp_1700.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_udp_1700"
  name                     = "worker-${each.key}_udp_1700"
  port                     = 30700 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_udp_1700
  ]
}

resource "oci_network_load_balancer_listener" "worker_udp_1700" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_udp_1700.name
  name                     = "worker_udp_1700"
  network_load_balancer_id = var.load_balancer_id
  port                     = 1700
  protocol                 = "UDP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_udp_1700,
    oci_network_load_balancer_backend.worker_udp_1700
  ]
}


# mosquito-mqtt-chirpstack-v3-proxied-tcp-1888
resource "oci_network_load_balancer_backend_set" "worker_tcp_1888" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_1888"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_1888" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_1888.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_1888"
  name                     = "worker-${each.key}_tcp_1888"
  port                     = 30888 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_1888
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_1888" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_1888.name
  name                     = "worker_tcp_1888"
  network_load_balancer_id = var.load_balancer_id
  port                     = 1888
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_1888,
    oci_network_load_balancer_backend.worker_tcp_1888
  ]
}


# postgresql-ns-chirpstack-v3-proxied-tcp-5437
resource "oci_network_load_balancer_backend_set" "worker_tcp_5437" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5437"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5437" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5437.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5437"
  name                     = "worker-${each.key}_tcp_5437"
  port                     = 30437 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5437
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5437" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5437.name
  name                     = "worker_tcp_5437"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5437
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5437,
    oci_network_load_balancer_backend.worker_tcp_5437
  ]
}


# postgresql-as-chirpstack-v3-proxied-tcp-5438
resource "oci_network_load_balancer_backend_set" "worker_tcp_5438" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5438"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5438" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5438.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5438"
  name                     = "worker-${each.key}_tcp_5438"
  port                     = 30438 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5438
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5438" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5438.name
  name                     = "worker_tcp_5438"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5438
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5438,
    oci_network_load_balancer_backend.worker_tcp_5438
  ]
}


# redis-chirpstack-v3-proxied-tcp-6384
resource "oci_network_load_balancer_backend_set" "worker_tcp_6384" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_6384"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_6384" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_6384.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_6384"
  name                     = "worker-${each.key}_tcp_6384"
  port                     = 30384 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_6384
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_6384" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_6384.name
  name                     = "worker_tcp_6384"
  network_load_balancer_id = var.load_balancer_id
  port                     = 6384
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_6384,
    oci_network_load_balancer_backend.worker_tcp_6384
  ]
}


# chirpstack-network-server-proxied-tcp-8000
resource "oci_network_load_balancer_backend_set" "worker_tcp_8000" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8000"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8000" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8000.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8000"
  name                     = "worker-${each.key}_tcp_8000"
  port                     = 31000 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8000
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8000" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8000.name
  name                     = "worker_tcp_8000"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8000
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8000,
    oci_network_load_balancer_backend.worker_tcp_8000
  ]
}


# chirpstack-application-server-proxied-tcp-8001
resource "oci_network_load_balancer_backend_set" "worker_tcp_8001" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8001"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8001" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8001.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8001"
  name                     = "worker-${each.key}_tcp_8001"
  port                     = 31001 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8001
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8001" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8001.name
  name                     = "worker_tcp_8001"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8001
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8001,
    oci_network_load_balancer_backend.worker_tcp_8001
  ]
}


# chirpstack-application-server-proxied-tcp-8003
resource "oci_network_load_balancer_backend_set" "worker_tcp_8003" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8003"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8003" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8003.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8003"
  name                     = "worker-${each.key}_tcp_8003"
  port                     = 31003 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8003
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8003" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8003.name
  name                     = "worker_tcp_8003"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8003
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8003,
    oci_network_load_balancer_backend.worker_tcp_8003
  ]
}


# chirpstack-application-server-proxied-tcp-8080
resource "oci_network_load_balancer_backend_set" "worker_tcp_8080" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8080"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8080" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8080.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8080"
  name                     = "worker-${each.key}_tcp_8080"
  port                     = 31080 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8080
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8080" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8080.name
  name                     = "worker_tcp_8080"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8080
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8080,
    oci_network_load_balancer_backend.worker_tcp_8080
  ]
}


# chirpstack-application-server-proxied-tcp-8101
resource "oci_network_load_balancer_backend_set" "worker_tcp_8101" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8101"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8101" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8101.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8101"
  name                     = "worker-${each.key}_tcp_8101"
  port                     = 31101 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8101
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8101" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8101.name
  name                     = "worker_tcp_8101"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8101
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8101,
    oci_network_load_balancer_backend.worker_tcp_8101
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for ChirpStack-v4


# chirpstack-gateway-bridge-chirpstack-v4-proxied-udp-1710
resource "oci_network_load_balancer_backend_set" "worker_udp_1710" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_udp_1710"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "UDP"
    port     = 1710
    request_data = "UElORw==" # PING
    response_data = "UE9ORw==" # PONG
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_udp_1710" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_udp_1710.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_udp_1710"
  name                     = "worker-${each.key}_udp_1710"
  port                     = 30710 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_udp_1710
  ]
}

resource "oci_network_load_balancer_listener" "worker_udp_1710" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_udp_1710.name
  name                     = "worker_udp_1710"
  network_load_balancer_id = var.load_balancer_id
  port                     = 1710
  protocol                 = "UDP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_udp_1710,
    oci_network_load_balancer_backend.worker_udp_1710
  ]
}


# # mosquito-mqtt-chirpstack-v4-proxied-tcp-1893
# resource "oci_network_load_balancer_backend_set" "worker_tcp_1893" {
#   network_load_balancer_id = var.load_balancer_id
#   name                     = "worker_tcp_1893"
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = true

#   health_checker {
#     protocol = "TCP"
#     port     = 22
#   }

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes = []
#     #ignore_changes = [backends]
#   }

#   timeouts {
#     create = "10m"
#     update = "10m"
#     delete = "10m"
#   }
# }

# resource "oci_network_load_balancer_backend" "worker_tcp_1893" {
#   #count                    = length(var.workers)
#   for_each                 = { for idx, worker in var.workers : idx => worker }
#   backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_1893.name
#   network_load_balancer_id = var.load_balancer_id
#   #name                     = "worker-${count.index}_tcp_1893"
#   name                     = "worker-${each.key}_tcp_1893"
#   port                     = 30893 # Nginx ingress-controller service NodePort.
#   #target_id                = var.workers[count.index].id
#   target_id                = each.value.id

#   depends_on = [
#     oci_network_load_balancer_backend_set.worker_tcp_1893
#   ]
# }

# resource "oci_network_load_balancer_listener" "worker_tcp_1893" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_1893.name
#   name                     = "worker_tcp_1893"
#   network_load_balancer_id = var.load_balancer_id
#   port                     = 1893
#   protocol                 = "TCP"

#   depends_on = [
#     oci_network_load_balancer_backend_set.worker_tcp_1893,
#     oci_network_load_balancer_backend.worker_tcp_1893
#   ]
# }


# mosquito-mqtt-chirpstack-v4-proxied-tcp-8883
resource "oci_network_load_balancer_backend_set" "worker_tcp_8883" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8883"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8883" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8883.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8883"
  name                     = "worker-${each.key}_tcp_8883"
  port                     = 30883 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8883
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8883" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8883.name
  name                     = "worker_tcp_8883"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8883
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8883,
    oci_network_load_balancer_backend.worker_tcp_8883
  ]
}


# postgresql-chirpstack-v4-proxied-tcp-5442
resource "oci_network_load_balancer_backend_set" "worker_tcp_5442" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5442"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5442" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5442.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5442"
  name                     = "worker-${each.key}_tcp_5442"
  port                     = 30442 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5442
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5442" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5442.name
  name                     = "worker_tcp_5442"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5442
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5442,
    oci_network_load_balancer_backend.worker_tcp_5442
  ]
}


# redis-chirpstack-v4-proxied-tcp-6389
resource "oci_network_load_balancer_backend_set" "worker_tcp_6389" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_6389"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_6389" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_6389.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_6389"
  name                     = "worker-${each.key}_tcp_6389"
  port                     = 30389 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_6389
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_6389" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_6389.name
  name                     = "worker_tcp_6389"
  network_load_balancer_id = var.load_balancer_id
  port                     = 6389
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_6389,
    oci_network_load_balancer_backend.worker_tcp_6389
  ]
}


# chirpstack-v4-proxied-tcp-8090
resource "oci_network_load_balancer_backend_set" "worker_tcp_8090" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8090"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8090" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8090.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8090"
  name                     = "worker-${each.key}_tcp_8090"
  port                     = 31090 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8090
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8090" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8090.name
  name                     = "worker_tcp_8090"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8090
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8090,
    oci_network_load_balancer_backend.worker_tcp_8090
  ]
}


# chirpstack-api-rest-v4-proxied-tcp-8100
resource "oci_network_load_balancer_backend_set" "worker_tcp_8100" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8100"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8100" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8100.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8100"
  name                     = "worker-${each.key}_tcp_8100"
  port                     = 31100 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8100
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8100" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8100.name
  name                     = "worker_tcp_8100"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8100
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8100,
    oci_network_load_balancer_backend.worker_tcp_8100
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Jenkins (Namespace: jenkins)


# jenkins-proxied-tcp-8088
resource "oci_network_load_balancer_backend_set" "worker_tcp_8088" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8088"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8088" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8088.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8088"
  name                     = "worker-${each.key}_tcp_8088"
  port                     = 30088 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8088
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8088" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8088.name
  name                     = "worker_tcp_8088"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8088
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8088,
    oci_network_load_balancer_backend.worker_tcp_8088
  ]
}


# jenkins-agent-proxied-tcp-50000
resource "oci_network_load_balancer_backend_set" "worker_tcp_50000" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_50000"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_50000" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_50000.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_50000"
  name                     = "worker-${each.key}_tcp_50000"
  port                     = 30500 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_50000
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_50000" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_50000.name
  name                     = "worker_tcp_50000"
  network_load_balancer_id = var.load_balancer_id
  port                     = 50000
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_50000,
    oci_network_load_balancer_backend.worker_tcp_50000
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Node-Red (Namespace: node-red)


# node-red-proxied-tcp-1885
resource "oci_network_load_balancer_backend_set" "worker_tcp_1885" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_1885"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_1885" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_1885.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_1885"
  name                     = "worker-${each.key}_tcp_1885"
  port                     = 30885 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_1885
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_1885" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_1885.name
  name                     = "worker_tcp_1885"
  network_load_balancer_id = var.load_balancer_id
  port                     = 1885
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_1885,
    oci_network_load_balancer_backend.worker_tcp_1885
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Grafana (Namespace: grafana)


# postgresql-grafana-proxied-tcp-5447
resource "oci_network_load_balancer_backend_set" "worker_tcp_5447" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5447"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5447" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5447.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5447"
  name                     = "worker-${each.key}_tcp_5447"
  port                     = 30447 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5447
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5447" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5447.name
  name                     = "worker_tcp_5447"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5447
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5447,
    oci_network_load_balancer_backend.worker_tcp_5447
  ]
}


# backend-grafana-proxied-tcp-3005
resource "oci_network_load_balancer_backend_set" "worker_tcp_3005" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_3005"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_3005" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_3005.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_3005"
  name                     = "worker-${each.key}_tcp_3005"
  port                     = 30005 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_3005
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_3005" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_3005.name
  name                     = "worker_tcp_3005"
  network_load_balancer_id = var.load_balancer_id
  port                     = 3005
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_3005,
    oci_network_load_balancer_backend.worker_tcp_3005
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for MongoDB (Namespace: adailsilva-apps)


# mongo-db-proxied-tcp-27017
resource "oci_network_load_balancer_backend_set" "worker_tcp_27017" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_27017"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_27017" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_27017.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_27017"
  name                     = "worker-${each.key}_tcp_27017"
  port                     = 32017 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_27017
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_27017" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_27017.name
  name                     = "worker_tcp_27017"
  network_load_balancer_id = var.load_balancer_id
  port                     = 27017
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_27017,
    oci_network_load_balancer_backend.worker_tcp_27017
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for MongoDB (Namespace: home-assistant)


# home-asssistant-proxied-tcp-8123
resource "oci_network_load_balancer_backend_set" "worker_tcp_8123" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8123"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8123" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8123.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8123"
  name                     = "worker-${each.key}_tcp_8123"
  port                     = 30123 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8123
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8123" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8123.name
  name                     = "worker_tcp_8123"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8123
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8123,
    oci_network_load_balancer_backend.worker_tcp_8123
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Spring Boot App arm64 (Namespace: adailsilva-apps)


# spring-boot-app-proxied-tcp-8081
resource "oci_network_load_balancer_backend_set" "worker_tcp_8081" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8081"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8081" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8081.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8081"
  name                     = "worker-${each.key}_tcp_8081"
  port                     = 32081 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8081
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8081" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8081.name
  name                     = "worker_tcp_8081"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8081
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8081,
    oci_network_load_balancer_backend.worker_tcp_8081
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Spring Boot App arm64 (Namespace: cardscontrol)


# postgresql-cardscontrol-proxied-tcp-5445
resource "oci_network_load_balancer_backend_set" "worker_tcp_5445" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5445"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5445" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5445.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5445"
  name                     = "worker-${each.key}_tcp_5445"
  port                     = 30445 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5445
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5445" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5445.name
  name                     = "worker_tcp_5445"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5445
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5445,
    oci_network_load_balancer_backend.worker_tcp_5445
  ]
}


# backend-cardscontrol-proxied-tcp-8083
resource "oci_network_load_balancer_backend_set" "worker_tcp_8083" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8083"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8083" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8083.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8083"
  name                     = "worker-${each.key}_tcp_8083"
  port                     = 30083 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8083
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8083" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8083.name
  name                     = "worker_tcp_8083"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8083
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8083,
    oci_network_load_balancer_backend.worker_tcp_8083
  ]
}


# --------------------------------------------------------------

# Load balancing configuration for Spring Boot App arm64 (Namespace: stockcontrol)


# postgresql-stockcontrol-proxied-tcp-5446
resource "oci_network_load_balancer_backend_set" "worker_tcp_5446" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_5446"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_5446" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_5446.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_5446"
  name                     = "worker-${each.key}_tcp_5446"
  port                     = 30446 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5446
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_5446" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_5446.name
  name                     = "worker_tcp_5446"
  network_load_balancer_id = var.load_balancer_id
  port                     = 5446
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_5446,
    oci_network_load_balancer_backend.worker_tcp_5446
  ]
}


# backend-stockcontrol-proxied-tcp-8084
resource "oci_network_load_balancer_backend_set" "worker_tcp_8084" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker_tcp_8084"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP"
    port     = 22
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = []
    #ignore_changes = [backends]
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "oci_network_load_balancer_backend" "worker_tcp_8084" {
  #count                    = length(var.workers)
  for_each                 = { for idx, worker in var.workers : idx => worker }
  backend_set_name         = oci_network_load_balancer_backend_set.worker_tcp_8084.name
  network_load_balancer_id = var.load_balancer_id
  #name                     = "worker-${count.index}_tcp_8084"
  name                     = "worker-${each.key}_tcp_8084"
  port                     = 30084 # Nginx ingress-controller service NodePort.
  #target_id                = var.workers[count.index].id
  target_id                = each.value.id

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8084
  ]
}

resource "oci_network_load_balancer_listener" "worker_tcp_8084" {
  default_backend_set_name = oci_network_load_balancer_backend_set.worker_tcp_8084.name
  name                     = "worker_tcp_8084"
  network_load_balancer_id = var.load_balancer_id
  port                     = 8084
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend_set.worker_tcp_8084,
    oci_network_load_balancer_backend.worker_tcp_8084
  ]
}
