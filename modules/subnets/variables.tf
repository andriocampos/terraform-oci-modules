variable "compartment_id" {
  description = "OCID do compartment"
  type        = string
}

variable "vcn_id" {
  description = "OCID da VCN"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada"
  type        = string
}

variable "public_subnet_name" {
  description = "Nome da subnet pública"
  type        = string
  default     = "subnet-pub-core"
}

variable "private_subnet_name" {
  description = "Nome da subnet privada"
  type        = string
  default     = "subnet-pvt-core"
}

variable "public_subnet_dns_label" {
  description = "DNS label da subnet pública"
  type        = string
  default     = "pubcore"
}

variable "private_subnet_dns_label" {
  description = "DNS label da subnet privada"
  type        = string
  default     = "pvtcore"
}

variable "route_table_public_id" {
  description = "OCID da Route Table para a subnet pública"
  type        = string
}

variable "route_table_private_id" {
  description = "OCID da Route Table para a subnet privada"
  type        = string
}

variable "security_list_public_id" {
  description = "OCID da Security List para a subnet pública"
  type        = string
}

variable "security_list_private_id" {
  description = "OCID da Security List para a subnet privada"
  type        = string
}

variable "freeform_tags" {
  description = "Tags de formato livre"
  type        = map(string)
  default     = {}
}
