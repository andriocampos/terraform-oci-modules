terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.26"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

locals {
  common_tags = {
    project     = "portfolio-sre"
    environment = "infra-core"
    managed_by  = "terraform"
  }
}

module "compartment" {
  source = "../../modules/compartment"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Compartment base para infraestrutura fixa do portfolio SRE"
  enable_delete         = true
  freeform_tags         = local.common_tags
}

module "vcn" {
  source = "../../modules/vcn"

  compartment_id  = module.compartment.id
  vcn_name        = "core-vcn"
  vcn_cidr_blocks = ["10.50.0.0/16"]
  vcn_dns_label   = "corevcn"
  freeform_tags   = local.common_tags
}

module "subnets" {
  source = "../../modules/subnets"

  compartment_id      = module.compartment.id
  vcn_id              = module.vcn.vcn_id
  public_subnet_cidr  = "10.50.1.0/24"
  private_subnet_cidr = "10.50.11.0/24"

  route_table_public_id    = module.vcn.route_table_public_id
  route_table_private_id   = module.vcn.route_table_private_id
  security_list_public_id  = module.vcn.security_list_public_id
  security_list_private_id = module.vcn.security_list_private_id

  freeform_tags = local.common_tags
}

output "compartment_id" {
  value = module.compartment.id
}

output "vcn_id" {
  value = module.vcn.vcn_id
}

output "public_subnet_id" {
  value = module.subnets.public_subnet_id
}

output "private_subnet_id" {
  value = module.subnets.private_subnet_id
}
