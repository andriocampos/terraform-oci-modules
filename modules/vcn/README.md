# Module: VCN

Creates a complete OCI Virtual Cloud Network stack including gateways, route tables, and security lists. Provides a production-ready networking foundation with public/private separation.

## Usage

```hcl
module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"

  compartment_id  = module.compartment.id
  vcn_name        = "core-vcn"
  vcn_cidr_blocks = ["10.50.0.0/16"]
  vcn_dns_label   = "corevcn"

  freeform_tags = {
    project    = "portfolio-sre"
    managed_by = "terraform"
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `compartment_id` | `string` | ✅ | — | Compartment OCID where VCN will be created |
| `vcn_name` | `string` | ✅ | — | VCN display name |
| `vcn_cidr_blocks` | `list(string)` | ✅ | — | CIDR blocks for the VCN (e.g., `["10.50.0.0/16"]`) |
| `vcn_dns_label` | `string` | ✅ | — | DNS label for the VCN (max 15 chars, alphanumeric, must start with letter) |
| `igw_display_name` | `string` | ❌ | `"igw-core"` | Internet Gateway display name |
| `sgw_display_name` | `string` | ❌ | `"sgw-core"` | Service Gateway display name |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Free-form tags to apply to all resources |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vcn_id` | `string` | VCN OCID |
| `igw_id` | `string` | Internet Gateway OCID |
| `sgw_id` | `string` | Service Gateway OCID |
| `route_table_public_id` | `string` | Public route table OCID |
| `route_table_private_id` | `string` | Private route table OCID |
| `security_list_public_id` | `string` | Public security list OCID |
| `security_list_private_id` | `string` | Private security list OCID |

## Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| `oci_core_vcn` | `{vcn_name}` | Virtual Cloud Network |
| `oci_core_internet_gateway` | `igw-core` | Public internet access (bidirectional) |
| `oci_core_service_gateway` | `sgw-core` | Access to OCI Services without NAT |
| `oci_core_route_table` | `rt-pub-core` | Routes for public subnet (0.0.0.0/0 → IGW) |
| `oci_core_route_table` | `rt-pvt-core` | Routes for private subnet (OCI Services → SGW) |
| `oci_core_security_list` | `sl-pub-core` | Firewall rules for public subnet |
| `oci_core_security_list` | `sl-pvt-core` | Firewall rules for private subnet |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ VCN: core-vcn                                           │
│                                                         │
│  ┌───────────────────┐       ┌───────────────────┐     │
│  │ rt-pub-core       │       │ rt-pvt-core       │     │
│  │ 0.0.0.0/0 → IGW  │       │ OCI Svc → SGW    │     │
│  └─────────┬─────────┘       └─────────┬─────────┘     │
│            │                           │               │
│  ┌─────────▼─────────┐       ┌─────────▼─────────┐     │
│  │ sl-pub-core       │       │ sl-pvt-core       │     │
│  │ IN: SSH any, ICMP │       │ IN: SSH VCN, ICMP │     │
│  │ OUT: ALL          │       │ OUT: ALL          │     │
│  └───────────────────┘       └───────────────────┘     │
│                                                         │
│  ┌──────────┐  ┌──────────┐                            │
│  │   IGW    │  │   SGW    │                            │
│  │(internet)│  │(OCI svc) │                            │
│  └────┬─────┘  └────┬─────┘                            │
└───────┼──────────────┼─────────────────────────────────-┘
        │              │
    Internet      OCI Services (repos, storage, registry)
```

## Security List Rules

### Public (`sl-pub-core`)

| Direction | Protocol | Port/Type | Source/Dest | Description |
|-----------|----------|-----------|-------------|-------------|
| Ingress | TCP | 22 | `0.0.0.0/0` | SSH from any |
| Ingress | ICMP | Type 3, Code 4 | `0.0.0.0/0` | Path MTU Discovery |
| Ingress | ICMP | Type 3 | VCN CIDR | Destination Unreachable |
| Egress | ALL | — | `0.0.0.0/0` | Allow all outbound |

### Private (`sl-pvt-core`)

| Direction | Protocol | Port/Type | Source/Dest | Description |
|-----------|----------|-----------|-------------|-------------|
| Ingress | TCP | 22 | VCN CIDR | SSH from VCN only |
| Ingress | ICMP | Type 3, Code 4 | VCN CIDR | Path MTU Discovery |
| Egress | ALL | — | `0.0.0.0/0` | Allow all outbound |

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Service Gateway instead of NAT Gateway | NAT GW costs ~$16.50/month. SGW is free and provides access to OCI repos, Object Storage, Container Registry |
| SSH open to 0.0.0.0/0 on public SL | Portfolio/lab environment. For production, restrict to known IPs or use Bastion service |
| ICMP rules included | Required for Path MTU Discovery — without these, large packets are silently dropped |
| Stateful rules (default) | Simplifies rule management — response traffic is automatically allowed |

## Cost

**Free** — All resources created by this module (VCN, IGW, SGW, Route Tables, Security Lists) are included in OCI Free Tier with no usage limits.
