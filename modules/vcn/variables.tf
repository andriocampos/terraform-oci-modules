variable "compartment_id" {
  description = "OCID do compartment onde a VCN será criada"
  type        = string
}

variable "vcn_name" {
  description = "Nome da VCN"
  type        = string
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks da VCN"
  type        = list(string)
}

variable "vcn_dns_label" {
  description = "DNS label da VCN"
  type        = string
}

variable "igw_display_name" {
  description = "Nome do Internet Gateway"
  type        = string
  default     = "igw-core"
}

variable "sgw_display_name" {
  description = "Nome do Service Gateway"
  type        = string
  default     = "sgw-core"
}

variable "freeform_tags" {
  description = "Tags de formato livre"
  type        = map(string)
  default     = {}
}
