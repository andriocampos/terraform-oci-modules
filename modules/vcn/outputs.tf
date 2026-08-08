output "vcn_id" {
  description = "OCID da VCN"
  value       = oci_core_vcn.this.id
}

output "igw_id" {
  description = "OCID do Internet Gateway"
  value       = oci_core_internet_gateway.this.id
}

output "sgw_id" {
  description = "OCID do Service Gateway"
  value       = oci_core_service_gateway.this.id
}

output "route_table_public_id" {
  description = "OCID da Route Table pública"
  value       = oci_core_route_table.public.id
}

output "route_table_private_id" {
  description = "OCID da Route Table privada"
  value       = oci_core_route_table.private.id
}

output "security_list_public_id" {
  description = "OCID da Security List pública"
  value       = oci_core_security_list.public.id
}

output "security_list_private_id" {
  description = "OCID da Security List privada"
  value       = oci_core_security_list.private.id
}
