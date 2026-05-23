resource "oci_core_subnet" "private" {
  count             = var.provision_private_subnet ? 1 : 0
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.1.0/24"
  route_table_id    = module.vcn.nat_route_id
  security_list_ids = [oci_core_security_list.private[0].id]
  display_name      = "private-subnet"
  dns_label         = var.private_subnet_dns_label
}

resource "oci_core_security_list" "private" {
  count          = var.provision_private_subnet ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "Security List for Private subnet"

  # Default rules
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    description      = "ALL Protocol - Default egress_security_rules."
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
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
      type = 3
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
      type = 3
    }
    description = "ICMP Protocol - ingress_security_rules - Type = 3."
  }

  # --------------------------------------------------------------

  # K8S API server
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet. This is a private subnet, but requests are forwarded via LB, and source IP is preserved.
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

  # NodePort Services
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Internet.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 30000
      max = 32767
    }
    description = "TCP Protocol - NodePort Services ingress_security_rules."
  }

  # Nginx ingress-controller Admission Webhook
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16" # Virtual Cloud Networks - VCN.
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 8443
      max = 8443
    }
    description = "TCP Protocol - Nginx ingress-controller Admission Webhook ingress_security_rules."
  }

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

}