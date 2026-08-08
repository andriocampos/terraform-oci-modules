output "id" {
  description = "OCID do compartment criado"
  value       = oci_identity_compartment.this.id
}

output "name" {
  description = "Nome do compartment"
  value       = oci_identity_compartment.this.name
}
