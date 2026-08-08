resource "oci_identity_compartment" "this" {
  compartment_id = var.parent_compartment_id
  name           = var.name
  description    = var.description
  enable_delete  = var.enable_delete

  freeform_tags = var.freeform_tags
}
