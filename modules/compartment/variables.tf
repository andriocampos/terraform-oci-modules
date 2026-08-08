variable "parent_compartment_id" {
  description = "OCID do compartment pai (geralmente o tenancy_ocid)"
  type        = string
}

variable "name" {
  description = "Nome do compartment"
  type        = string
}

variable "description" {
  description = "Descrição do compartment"
  type        = string
  default     = "Managed by Terraform"
}

variable "enable_delete" {
  description = "Permitir exclusão do compartment via Terraform"
  type        = bool
  default     = true
}

variable "freeform_tags" {
  description = "Tags de formato livre"
  type        = map(string)
  default     = {}
}
