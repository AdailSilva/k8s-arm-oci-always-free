module "compartment" {
  source                              = "./compartment"
  tenancy_ocid                        = var.tenancy_ocid
  compartment = {
    name                              = "k8s-on-arm-oci-always-free"
    description                       = "Compartment for Terraform'ed resources"
  }
}

module "network" {
  source                              = "./network"
  compartment_id                      = module.compartment.id
  region                              = var.region
  vcn_dns_label                       = "vcn"
  public_subnet_dns_label             = "public"
  provision_private_subnet            = false
}

module "compute" {
  source                              = "./compute"
  compartment_id                      = module.compartment.id
  ssh_key_pub_path                    = var.ssh_key_pub_path
  load_balancer_id                    = module.network.load_balancer_id
  availability_domain                 = 0
  
  # Link images: https://docs.oracle.com/en-us/iaas/images/ubuntu-2404/index.htm
  leader = {
    shape                             = "VM.Standard.A1.Flex"
    image                             = "Canonical-Ubuntu-24.04-aarch64-2026.02.28-0"
    # image                             = "Canonical-Ubuntu-24.04-Minimal-aarch64-2026.02.28-0"
    # shape                             = "VM.Standard.E2.1.Micro"
    # image                             = "Canonical-Ubuntu-24.04-2026.02.28-0"
    # image                             = "Canonical-Ubuntu-24.04-Minimal-2026.02.28-0"
    ocpus                             = 1
    memory_in_gbs                     = 3
    hostname                          = "leader"
    subnet_id                         = module.network.public_subnet_id
    assign_public_ip                  = true
  }
  
  workers = {
    shape                             = "VM.Standard.A1.Flex"
    image                             = "Canonical-Ubuntu-24.04-aarch64-2026.02.28-0"
    # image                             = "Canonical-Ubuntu-24.04-Minimal-aarch64-2026.02.28-0"
    # shape                             = "VM.Standard.E2.1.Micro"
    # image                             = "Canonical-Ubuntu-24.04-2026.02.28-0"
    # image                             = "Canonical-Ubuntu-24.04-Minimal-2026.02.28-0"
    count                             = 3
    ocpus                             = 1
    memory_in_gbs                     = 7
    base_hostname                     = "worker"
    subnet_id                         = module.network.public_subnet_id
    assign_public_ip                  = true
  }
}

module "k8s" {
  source                              = "./k8s"
  ssh_key_path                        = var.ssh_key_path
  cluster_public_ip                   = module.network.reserved_public_ip.ip_address
  cluster_public_dns_name             = var.cluster_public_dns_name
  load_balancer_id                    = module.network.load_balancer_id
  leader                              = module.compute.leader
  workers                             = module.compute.workers
  linux_overwrite_local_kube_config = var.linux_overwrite_local_kube_config
  # windows_overwrite_local_kube_config = var.windows_overwrite_local_kube_config
}

module "k8s_scaffold" {
  source                              = "./k8s_scaffold"
  depends_on                          = [module.k8s]
  ssh_key_path                        = var.ssh_key_path
  cluster_public_ip                   = module.network.reserved_public_ip.ip_address
  cluster_public_dns_name             = var.cluster_public_dns_name
  letsencrypt_registration_email      = var.letsencrypt_registration_email
  load_balancer_id                    = module.network.load_balancer_id
  leader                              = module.compute.leader
  workers                             = module.compute.workers
  debug_create_cluster_admin          = var.debug_create_cluster_admin
}

module "oci-infra_ci_cd" {
  source                              = "./oci_artifacts_container_repository"
  depends_on                          = [module.k8s_scaffold]
  compartment_id                      = module.compartment.id
}

output "cluster_public_ip" {
  value                               = module.network.reserved_public_ip.ip_address
}

output "cluster_public_address" {
  value                               = var.cluster_public_dns_name
}

output "admin_token" {
  value                               = module.k8s_scaffold.admin_token
}
