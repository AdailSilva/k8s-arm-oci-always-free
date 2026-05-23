resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.0.0/24"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public.id]
  display_name      = "public-subnet"
  dns_label         = var.public_subnet_dns_label
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "Security List for Public subnet"

  # Default rules
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0" # Internet.
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    description      = "ALL Protocol - Default egress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 22
      max = 22
    }
    description = "TCP Protocol - SSH ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.ICMP

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3 # Destination Unreachable.
      code = 4
    }
    description = "ICMP Protocol - ingress_security_rules - Type = 3, Code = 4."
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.ICMP

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3 # Destination Unreachable.
    }
    description = "ICMP Protocol - ingress_security_rules - Type = 3."
  }

  # --------------------------------------------------------------

  # ICMP Echo Reply configuration

  # ICMP Echo Reply - ingress_security_rules
  ingress_security_rules {
    protocol         = "1" # ICMP Protocol.
    source           = "0.0.0.0/0"
    source_type      = "CIDR_BLOCK"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 8 # Echo.
      code = 0
    }
    description = "ICMP Protocol - ICMP Echo Request ingress_security_rules (Allow ICMP Ping Requests - OCI)."
  }

  # ICMP Echo Reply - egress_security_rules
  egress_security_rules {
    protocol         = "1" # ICMP Protocol.
    destination      = "0.0.0.0/0" # Or specific destination IP.
    destination_type = "CIDR_BLOCK"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 0 # Echo Reply.
      code = 0
    }
    description = "ICMP Protocol - ICMP Echo Reply egress_security_rules (Allow ICMP Ping Replies - OCI)."
  }

  # --------------------------------------------------------------

  # K8S API server
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "TCP Protocol - K8S API server ingress_security_rules."
  }

  # Kubelet API
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 10250
      max = 10250
    }
    description = "TCP Protocol - Kubelet API ingress_security_rules."
  }

  # Flannel
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.UDP
    udp_options {
      min = 8472
      max = 8472
    }
    description = "UDP Protocol - Flannel ingress_security_rules."
  }

  # --------------------------------------------------------------

  # http-kubernetes-dashboard-v2-7-0 (HTTP)
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 80
      max = 80
    }
    description = "TCP Protocol - HTTP ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30080
      max = 30080
    }
    description = "TCP Protocol - HTTP NodePort ingress_security_rules."
  }

  # --------------------------------------------------------------

  # https-kubernetes-dashboard-v2-7-0 (HTTPS)
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 443
      max = 443
    }
    description = "TCP Protocol - HTTPS ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30443
      max = 30443
    }
    description = "TCP Protocol - HTTPS NodePort ingress_security_rules."
  }

# --------------------------------------------------------------

  # Health Check configuration

  # Health Check - ingress_security_rules
  # INGRESS (uplink - gateway -> ChirpStack)
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    #source      = "10.0.0.101/32" # Virtual Cloud Networks - VCN (NLB IP).
    source_type = "CIDR_BLOCK"
    protocol    = "17" # UDP Protocol.
    #protocol    = local.protocol.UDP
    udp_options {
      min = 1700
      max = 1700
    }
    description = "UDP Protocol - Health Check ingress_security_rules for port 1700 from Network Load Balancer - OCI."
  }

  # EGRESS (downlink - ChirpStack -> gateway)
  egress_security_rules {
    stateless   = false
    destination = "0.0.0.0/0" # Restrinjir para IPs dos gateways.
    destination_type = "CIDR_BLOCK"
    protocol    = "17" # UDP
    udp_options {
      min = 1700
      max = 1700
    }
    description = "Allow UDP/1710 egress to gateways (downlink)"
  }

  # INGRESS (uplink - gateway -> ChirpStack)
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    #source      = "10.0.0.101/32" # Virtual Cloud Networks - VCN (NLB IP).
    source_type = "CIDR_BLOCK"
    protocol    = "17" # UDP Protocol.
    #protocol    = local.protocol.UDP
    udp_options {
      min = 1710
      max = 1710
    }
    description = "UDP Protocol - Health Check ingress_security_rules for port 1710 from Network Load Balancer - OCI."
  }

  # EGRESS (downlink - ChirpStack -> gateway)
  egress_security_rules {
    stateless   = false
    destination = "0.0.0.0/0" # Restrinjir para IPs dos gateways.
    destination_type = "CIDR_BLOCK"
    protocol    = "17" # UDP
    udp_options {
      min = 1710
      max = 1710
    }
    description = "Allow UDP/1710 egress to gateways (downlink)"
  }

  # Health Check - egress_security_rules
  # egress_security_rules {
  #   stateless        = false
  #   destination      = "0.0.0.0/0"
  #   #destination      = "10.0.0.101/32" # Virtual Cloud Networks - VCN (NLB IP).
  #   destination_type = "CIDR_BLOCK"
  #   protocol         = "17" # UDP Protocol.
  #   #protocol         = local.protocol.UDP
  #   udp_options {
  #     min = 1024
  #     max = 65535
  #   }
  #   description = "UDP Protocol - Health Check egress_security_rules for Network Load Balancer - OCI."
  # }

# --------------------------------------------------------------

  # File Storage configuration

  # File Storage - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 111
      max = 111
    }
    description = "TCP Protocol - File Storage ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 2048
      max = 2050
    }
    description = "TCP Protocol - File Storage ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.UDP
    udp_options {
      min = 111
      max = 111
    }
    description = "UDP Protocol - File Storage ingress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.UDP
    udp_options {
      min = 2048
      max = 2048
    }
    description = "UDP Protocol - File Storage ingress_security_rules."
  }

  # File Storage - egress_security_rules
  egress_security_rules {
    stateless        = false
    destination      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    destination_type = "CIDR_BLOCK"
    protocol         = local.protocol.TCP
    tcp_options {
      min = 111
      max = 111
    }
    description      = "TCP Protocol - File Storage egress_security_rules."
  }

  egress_security_rules {
    stateless        = false
    destination      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    destination_type = "CIDR_BLOCK"
    protocol         = local.protocol.TCP
    tcp_options {
      min = 2048
      max = 2050
    }
    description      = "TCP Protocol - File Storage egress_security_rules."
  }

  egress_security_rules {
    stateless        = false
    destination      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    destination_type = "CIDR_BLOCK"
    protocol         = local.protocol.UDP
    udp_options {
      min = 111
      max = 111
    }
    description      = "UDP Protocol - File Storage egress_security_rules."
  }

  # --------------------------------------------------------------

  # ChirpStack-v3 configuration

  # chirpstack-gateway-bridge - ingress_security_rules
  # ingress_security_rules {
  #   stateless   = false
  #   source      = "0.0.0.0/0" # Internet.
  #   source_type = "CIDR_BLOCK"
  #   protocol    = local.protocol.UDP
  #   udp_options {
  #     min = 1700
  #     max = 1700
  #   }
  #   description = "UDP Protocol - chirpstack-gateway-bridge ingress_security_rules. (ChirpStack-v3)"
  # }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.UDP
    udp_options {
      min = 30700
      max = 30700
    }
    description = "UDP Protocol - chirpstack-gateway-bridge ingress_security_rules (ChirpStack-v3)."
  }

  # mosquitto-mqtt - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 1888
      max = 1888
    }
    description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30888
      max = 30888
    }
    description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v3)."
  }

  # postgresql-ns - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5437
      max = 5437
    }
    description = "TCP Protocol - postgresql-ns ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30437
      max = 30437
    }
    description = "TCP Protocol - postgresql-ns ingress_security_rules (ChirpStack-v3)."
  }

  # postgresql-as - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5438
      max = 5438
    }
    description = "TCP Protocol - postgresql-as ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30438
      max = 30438
    }
    description = "TCP Protocol - postgresql-as ingress_security_rules (ChirpStack-v3)."
  }

  # redis - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 6384
      max = 6384
    }
    description = "TCP Protocol - redis ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30384
      max = 30384
    }
    description = "TCP Protocol - redis ingress_security_rules (ChirpStack-v3)."
  }

  # chirpstack-network-server - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8000
      max = 8000
    }
    description = "TCP Protocol - chirpstack-network-server ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31000
      max = 31000
    }
    description = "TCP Protocol - chirpstack-network-server ingress_security_rules (ChirpStack-v3)."
  }

  # chirpstack-application-server - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8001
      max = 8001
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31001
      max = 31001
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  # chirpstack-application-server - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8003
      max = 8003
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31003
      max = 31003
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  # chirpstack-application-server - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8080
      max = 8080
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31080
      max = 31080
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  # chirpstack-application-server - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8101
      max = 8101
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31101
      max = 31101
    }
    description = "TCP Protocol - chirpstack-application-server ingress_security_rules (ChirpStack-v3)."
  }

  # --------------------------------------------------------------

  # ChirpStack-v4 configuration

  # chirpstack-gateway-bridge - ingress_security_rules
  # ingress_security_rules {
  #   stateless   = false
  #   source      = "0.0.0.0/0" # Internet.
  #   source_type = "CIDR_BLOCK"
  #   protocol    = local.protocol.UDP
  #   udp_options {
  #     min = 1710
  #     max = 1710
  #   }
  #   description = "UDP Protocol - chirpstack-gateway-bridge ingress_security_rules (ChirpStack-v4)."
  # }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.UDP
    udp_options {
      min = 30710
      max = 30710
    }
    description = "UDP Protocol - chirpstack-gateway-bridge ingress_security_rules (ChirpStack-v4)."
  }

  # # mosquitto-mqtt - ingress_security_rules
  # ingress_security_rules {
  #   stateless   = false
  #   source      = "0.0.0.0/0" # Internet.
  #   source_type = "CIDR_BLOCK"
  #   protocol    = local.protocol.TCP
  #   tcp_options {
  #     min = 1893
  #     max = 1893
  #   }
  #   description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v4)."
  # }

  # ingress_security_rules {
  #   stateless   = false
  #   source      = "0.0.0.0/0" # Internet.
  #   source_type = "CIDR_BLOCK"
  #   protocol    = local.protocol.TCP
  #   tcp_options {
  #     min = 30893
  #     max = 30893
  #   }
  #   description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v4)."
  # }

  # mosquitto-mqtt - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8883
      max = 8883
    }
    description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v4)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30883
      max = 30883
    }
    description = "TCP Protocol - mosquitto-mqtt ingress_security_rules (ChirpStack-v4)."
  }

  # postgresql - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5442
      max = 5442
    }
    description = "TCP Protocol - postgresql ingress_security_rules (ChirpStack-v4)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30442
      max = 30442
    }
    description = "TCP Protocol - postgresql ingress_security_rules (ChirpStack-v4)."
  }

  # redis - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 6389
      max = 6389
    }
    description = "TCP Protocol - redis ingress_security_rules (ChirpStack-v4)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30389
      max = 30389
    }
    description = "TCP Protocol - redis ingress_security_rules (ChirpStack-v4)."
  }

  # chirpstack-v4 - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8090
      max = 8090
    }
    description = "TCP Protocol - chirpstack-v4 ingress_security_rules (ChirpStack-v4)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31090
      max = 31090
    }
    description = "TCP Protocol - chirpstack-v4 ingress_security_rules (ChirpStack-v4)."
  }

  # chirpstack-rest-api - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8100
      max = 8100
    }
    description = "TCP Protocol - chirpstack-rest-api ingress_security_rules (ChirpStack-v4)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 31100
      max = 31100
    }
    description = "TCP Protocol - chirpstack-rest-api ingress_security_rules (ChirpStack-v4)."
  }

  # --------------------------------------------------------------

  # Jenkins configuration

  # jenkins - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8080
      max = 8080
    }
    description = "TCP Protocol - jenkins ingress_security_rules (jenkins)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30088
      max = 30088
    }
    description = "TCP Protocol - jenkins ingress_security_rules (jenkins)."
  }

  # jenkins-agent - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 50000
      max = 50000
    }
    description = "TCP Protocol - jenkins-agent ingress_security_rules (jenkins)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30500
      max = 30500
    }
    description = "TCP Protocol - jenkins ingress_security_rules (jenkins)."
  }

  # --------------------------------------------------------------

  # Node-RED configuration

  # node-red - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 1885
      max = 1885
    }
    description = "TCP Protocol - node-red ingress_security_rules (node-red)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30885
      max = 30885
    }
    description = "TCP Protocol - node-red ingress_security_rules (node-red)."
  }

  # --------------------------------------------------------------

  # Grafana configuration

  # postgresql - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5447
      max = 5447
    }
    description = "TCP Protocol - postgresql ingress_security_rules (grafana)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30447
      max = 30447
    }
    description = "TCP Protocol - postgresql ingress_security_rules (grafana)."
  }

  # backend - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 3005
      max = 3005
    }
    description = "TCP Protocol - backend ingress_security_rules (grafana)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30005
      max = 30005
    }
    description = "TCP Protocol - backend ingress_security_rules (grafana)."
  }

  # --------------------------------------------------------------

  # Mongo-DB - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 27017
      max = 27017
    }
    description = "TCP Protocol - mongo-db ingress_security_rules (adailsilva-apps)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 32017
      max = 32017
    }
    description = "TCP Protocol - mongo-db ingress_security_rules (adailsilva-apps)."
  }

  # --------------------------------------------------------------

  # Home Assistant - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8123
      max = 8123
    }
    description = "TCP Protocol - mongo-db ingress_security_rules (home-assistant)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8123
      max = 8123
    }
    description = "TCP Protocol - mongo-db ingress_security_rules (home-assistant)."
  }

  # --------------------------------------------------------------

  # Spring Boot Apps configuration

  # spring-boot-app-arm64 - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8081
      max = 8081
    }
    description = "TCP Protocol - spring-boot-app-arm64 ingress_security_rules (adailsilva-apps)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 32081
      max = 32081
    }
    description = "TCP Protocol - spring-boot-app-arm64 ingress_security_rules (adailsilva-apps)."
  }

  # spring-boot-app-arm64 - egress_security_rules
  egress_security_rules {
    stateless        = false
    destination      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    destination_type = "CIDR_BLOCK"
    protocol         = local.protocol.UDP
    udp_options {
      min = 8081
      max = 8081
    }
    description      = "TCP Protocol - spring-boot-app-arm64 egress_security_rules (adailsilva-apps)."
  }

  # --------------------------------------------------------------

  # Spring Boot Apps configuration

  # postgresql - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5445
      max = 5445
    }
    description = "TCP Protocol - postgresql ingress_security_rules (cardscontrol)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30445
      max = 30445
    }
    description = "TCP Protocol - postgresql ingress_security_rules (cardscontrol)."
  }

  # backend - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8083
      max = 8083
    }
    description = "TCP Protocol - backend ingress_security_rules (cardscontrol)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30083
      max = 30083
    }
    description = "TCP Protocol - backend ingress_security_rules (cardscontrol)."
  }

  # --------------------------------------------------------------

  # Spring Boot Apps configuration

  # postgresql - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 5446
      max = 5446
    }
    description = "TCP Protocol - postgresql ingress_security_rules (stockcontrol)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30446
      max = 30446
    }
    description = "TCP Protocol - postgresql ingress_security_rules (stockcontrol)."
  }

  # backend - ingress_security_rules
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8084
      max = 8084
    }
    description = "TCP Protocol - backend ingress_security_rules (stockcontrol)."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30084
      max = 30084
    }
    description = "TCP Protocol - backend ingress_security_rules (stockcontrol)."
  }
}