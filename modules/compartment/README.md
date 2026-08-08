# Module: Compartment

Creates an OCI Identity Compartment with lifecycle management support.

## Usage

```hcl
module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Core infrastructure compartment"
  enable_delete         = true

  freeform_tags = {
    project    = "portfolio-sre"
    managed_by = "terraform"
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `parent_compartment_id` | `string` | ✅ | — | OCID of the parent compartment (typically `tenancy_ocid` for top-level) |
| `name` | `string` | ✅ | — | Display name for the compartment |
| `description` | `string` | ❌ | `"Managed by Terraform"` | Description of the compartment |
| `enable_delete` | `bool` | ❌ | `true` | Whether Terraform can destroy this compartment |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Free-form tags to apply |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | OCID of the created compartment |
| `name` | `string` | Display name of the compartment |

## Resource Created

| Resource | API Reference |
|----------|---------------|
| `oci_identity_compartment` | [Docs](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_compartment) |

## Notes

- Compartment creation is an **IAM operation** — it happens at the tenancy level regardless of region.
- After creation, allow **~30 seconds** for the compartment to propagate before creating resources inside it. Terraform handles this implicitly via dependency graph.
- Setting `enable_delete = false` prevents accidental `terraform destroy` from removing the compartment and all resources within it.

## Cost

**Free** — Compartments are an identity construct with no associated billing.
