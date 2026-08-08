# ==============================================================================
# VCN
# ==============================================================================

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
  cidr_blocks    = var.vcn_cidr_blocks
  dns_label      = var.vcn_dns_label

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Internet Gateway (subnet pública)
# ==============================================================================

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = var.igw_display_name
  enabled        = true

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Service Gateway (subnet privada - acesso a OCI Services sem NAT)
# ==============================================================================

data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = var.sgw_display_name

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Route Table - Pública (rota para Internet Gateway)
# ==============================================================================

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-pub-core"

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Trafego para Internet via IGW"
  }

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Route Table - Privada (rota para Service Gateway)
# ==============================================================================

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-pvt-core"

  route_rules {
    network_entity_id = oci_core_service_gateway.this.id
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "Trafego para OCI Services via SGW"
  }

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Security List - Pública
# ==============================================================================

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-pub-core"

  # Egress: permitir tudo
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
    description = "Permitir todo trafego de saida"
  }

  # Ingress: SSH (porta 22)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "6" # TCP
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }

    description = "SSH de qualquer origem"
  }

  # Ingress: ICMP tipo 3 cod 4 (Path MTU Discovery)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1" # ICMP
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }

    description = "ICMP Path MTU Discovery"
  }

  # Ingress: ICMP tipo 3 da VCN (Destination Unreachable)
  ingress_security_rules {
    source    = var.vcn_cidr_blocks[0]
    protocol  = "1"
    stateless = false

    icmp_options {
      type = 3
    }

    description = "ICMP Destination Unreachable da VCN"
  }

  freeform_tags = var.freeform_tags
}

# ==============================================================================
# Security List - Privada
# ==============================================================================

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-pvt-core"

  # Egress: permitir tudo (OCI services via SGW)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
    description = "Permitir todo trafego de saida"
  }

  # Ingress: SSH somente da VCN (acesso interno)
  ingress_security_rules {
    source    = var.vcn_cidr_blocks[0]
    protocol  = "6"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }

    description = "SSH somente da VCN"
  }

  # Ingress: ICMP tipo 3 cod 4 da VCN
  ingress_security_rules {
    source    = var.vcn_cidr_blocks[0]
    protocol  = "1"
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }

    description = "ICMP Path MTU Discovery da VCN"
  }

  freeform_tags = var.freeform_tags
}
