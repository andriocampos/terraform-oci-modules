<p align="center">
  <img src="https://img.shields.io/badge/OCI-Oracle_Cloud-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="OCI"/>
  <img src="https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/>
  <img src="https://img.shields.io/github/v/tag/andriocampos/terraform-oci-modules?style=for-the-badge&label=latest&color=blue" alt="Latest Tag"/>
  <img src="https://img.shields.io/github/license/andriocampos/terraform-oci-modules?style=for-the-badge" alt="License"/>
</p>

# Terraform OCI Modules

Reusable, production-grade Terraform modules for Oracle Cloud Infrastructure (OCI). Designed for composability, idempotency, and Free Tier compatibility.

---

## Overview

This repository provides a curated set of Terraform modules for provisioning core OCI networking and identity resources. Each module follows the [Terraform Module Standard](https://developer.hashicorp.com/terraform/language/modules/develop/structure) and is independently versioned via Git tags.

### Design Principles

- **Minimal blast radius** — each module manages a single concern
- **Free Tier first** — default configurations stay within OCI Always Free limits
- **Pin-and-forget** — consumers reference a `?ref=vX.Y.Z` tag for stability
- **Zero secrets in code** — all sensitive values are injected via variables

---

## Modules

| Module | Description | Resources |
|--------|-------------|-----------|
| [`compartment`](./modules/compartment/) | Identity compartment with lifecycle control | `oci_identity_compartment` |
| [`vcn`](./modules/vcn/) | Full networking stack | VCN, IGW, SGW, Route Tables, Security Lists |
| [`subnets`](./modules/subnets/) | Public + Private subnets | `oci_core_subnet` × 2 |

---

## Quick Start

```hcl
module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Core infrastructure compartment"
  freeform_tags         = { managed_by = "terraform" }
}

module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"

  compartment_id  = module.compartment.id
  vcn_name        = "core-vcn"
  vcn_cidr_blocks = ["10.50.0.0/16"]
  vcn_dns_label   = "corevcn"
}

module "subnets" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/subnets?ref=v1.0.0"

  compartment_id      = module.compartment.id
  vcn_id              = module.vcn.vcn_id
  public_subnet_cidr  = "10.50.1.0/24"
  private_subnet_cidr = "10.50.11.0/24"

  route_table_public_id    = module.vcn.route_table_public_id
  route_table_private_id   = module.vcn.route_table_private_id
  security_list_public_id  = module.vcn.security_list_public_id
  security_list_private_id = module.vcn.security_list_private_id
}
```

---

## Module Reference

### `modules/compartment`

#### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent_compartment_id` | `string` | ✅ | — | OCID of parent compartment |
| `name` | `string` | ✅ | — | Compartment name |
| `description` | `string` | ❌ | `"Managed by Terraform"` | Compartment description |
| `enable_delete` | `bool` | ❌ | `true` | Allow Terraform to destroy |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Free-form tags |

#### Outputs

| Name | Description |
|------|-------------|
| `id` | Compartment OCID |
| `name` | Compartment name |

---

### `modules/vcn`

#### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `compartment_id` | `string` | ✅ | — | Compartment OCID |
| `vcn_name` | `string` | ✅ | — | VCN display name |
| `vcn_cidr_blocks` | `list(string)` | ✅ | — | VCN CIDR blocks |
| `vcn_dns_label` | `string` | ✅ | — | VCN DNS label |
| `igw_display_name` | `string` | ❌ | `"igw-core"` | Internet Gateway name |
| `sgw_display_name` | `string` | ❌ | `"sgw-core"` | Service Gateway name |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Free-form tags |

#### Outputs

| Name | Description |
|------|-------------|
| `vcn_id` | VCN OCID |
| `igw_id` | Internet Gateway OCID |
| `sgw_id` | Service Gateway OCID |
| `route_table_public_id` | Public route table OCID |
| `route_table_private_id` | Private route table OCID |
| `security_list_public_id` | Public security list OCID |
| `security_list_private_id` | Private security list OCID |

#### Networking Topology

```
┌─────────────────────────────────────────────────┐
│ VCN                                             │
│                                                 │
│  ┌─────────────┐         ┌─────────────┐       │
│  │ RT Public   │         │ RT Private  │       │
│  │ 0.0.0.0/0→IGW│        │ OCI Svc→SGW │       │
│  └──────┬──────┘         └──────┬──────┘       │
│         │                       │               │
│  ┌──────▼──────┐         ┌──────▼──────┐       │
│  │  SL Public  │         │ SL Private  │       │
│  │ SSH: any    │         │ SSH: VCN    │       │
│  └─────────────┘         └─────────────┘       │
│                                                 │
│  ┌─────────┐  ┌─────────┐                      │
│  │   IGW   │  │   SGW   │                      │
│  └────┬────┘  └────┬────┘                      │
└───────┼─────────────┼──────────────────────────-┘
        │             │
    Internet      OCI Services
```

---

### `modules/subnets`

#### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `compartment_id` | `string` | ✅ | — | Compartment OCID |
| `vcn_id` | `string` | ✅ | — | VCN OCID |
| `public_subnet_cidr` | `string` | ✅ | — | Public subnet CIDR |
| `private_subnet_cidr` | `string` | ✅ | — | Private subnet CIDR |
| `public_subnet_name` | `string` | ❌ | `"subnet-pub-core"` | Public subnet name |
| `private_subnet_name` | `string` | ❌ | `"subnet-pvt-core"` | Private subnet name |
| `public_subnet_dns_label` | `string` | ❌ | `"pubcore"` | Public subnet DNS label |
| `private_subnet_dns_label` | `string` | ❌ | `"pvtcore"` | Private subnet DNS label |
| `route_table_public_id` | `string` | ✅ | — | Public route table OCID |
| `route_table_private_id` | `string` | ✅ | — | Private route table OCID |
| `security_list_public_id` | `string` | ✅ | — | Public security list OCID |
| `security_list_private_id` | `string` | ✅ | — | Private security list OCID |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Free-form tags |

#### Outputs

| Name | Description |
|------|-------------|
| `public_subnet_id` | Public subnet OCID |
| `private_subnet_id` | Private subnet OCID |
| `public_subnet_cidr` | Public subnet CIDR |
| `private_subnet_cidr` | Private subnet CIDR |

---

## Requirements

| Dependency | Version |
|------------|---------|
| Terraform | `>= 1.5.0` |
| Provider `oracle/oci` | `~> 8.26` |
| Git (SSH access) | For module sourcing |

---

## Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

| Bump | When |
|------|------|
| **MAJOR** | Breaking changes to existing variables or outputs |
| **MINOR** | New modules or backward-compatible features |
| **PATCH** | Documentation or bug fixes |

Always pin to a specific tag in your source:

```hcl
source = "git::ssh://...?ref=v1.0.0"  # ✅ pinned
source = "git::ssh://..."              # ❌ unstable (follows HEAD)
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Usage Guide](./docs/USAGE_GUIDE.md) | Complete guide: prerequisites, auth setup, step-by-step deploy, versioning, troubleshooting |
| [Module: compartment](./modules/compartment/README.md) | Inputs, outputs, notes |
| [Module: vcn](./modules/vcn/README.md) | Inputs, outputs, architecture, security rules |
| [Module: subnets](./modules/subnets/README.md) | Inputs, outputs, CIDR planning, public vs private behavior |

## Examples

| Example | Description |
|---------|-------------|
| [infra-core](./examples/infra-core/) | Complete landing zone: compartment + VCN + subnets |

---

## Contributing

1. Create a feature branch from `main`
2. Make changes following existing patterns
3. Run `terraform fmt -recursive` and `terraform validate`
4. Update `CHANGELOG.md`
5. Open a Pull Request

---

## License

[MIT](./LICENSE)
