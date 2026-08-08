# ==============================================================================
# Subnet Pública
# ==============================================================================

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = var.vcn_id
  display_name               = var.public_subnet_name
  cidr_block                 = var.public_subnet_cidr
  dns_label                  = var.public_subnet_dns_label
  route_table_id             = var.route_table_public_id
  security_list_ids          = [var.security_list_public_id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Subnet Privada
# ==============================================================================

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = var.vcn_id
  display_name               = var.private_subnet_name
  cidr_block                 = var.private_subnet_cidr
  dns_label                  = var.private_subnet_dns_label
  route_table_id             = var.route_table_private_id
  security_list_ids          = [var.security_list_private_id]
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true

  freeform_tags = var.freeform_tags
}
