output "public_subnet_id" {
  description = "OCID da subnet pública"
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "OCID da subnet privada"
  value       = oci_core_subnet.private.id
}

output "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  value       = oci_core_subnet.public.cidr_block
}

output "private_subnet_cidr" {
  description = "CIDR da subnet privada"
  value       = oci_core_subnet.private.cidr_block
}
