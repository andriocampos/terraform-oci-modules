# Usage Guide

Complete guide for consuming modules from this repository in your Terraform projects.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication Setup](#authentication-setup)
- [Module Sourcing](#module-sourcing)
- [Step-by-Step: Deploy a Landing Zone](#step-by-step-deploy-a-landing-zone)
- [Version Pinning](#version-pinning)
- [Upgrading Modules](#upgrading-modules)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 | IaC engine |
| [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) | Latest | API key generation & config |
| Git | Latest | Module sourcing via SSH |
| SSH Key | — | GitHub access for `git::ssh://` sources |

### Verify Installation

```bash
terraform version   # >= 1.5.0
oci --version       # any
git --version       # any
ssh -T git@github.com  # should say "Hi <user>! You've successfully authenticated"
```

---

## Authentication Setup

### 1. Generate OCI API Key

```bash
# Generate key pair (if you don't have one)
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
chmod 600 ~/.oci/oci_api_key.pem
```

### 2. Upload Public Key to OCI Console

1. Go to **Profile** → **API Keys** → **Add API Key**
2. Choose **Paste Public Key**
3. Paste contents of `~/.oci/oci_api_key_public.pem`
4. Note the **fingerprint** shown after upload

### 3. Configure `~/.oci/config`

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaa...
fingerprint=aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
key_file=~/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..aaaaaaa...
region=sa-saopaulo-1
```

### 4. Create `terraform.tfvars`

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaa..."
user_ocid        = "ocid1.user.oc1..aaaaaaa..."
fingerprint      = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "sa-saopaulo-1"
```

> ⚠️ **Never commit `terraform.tfvars`** — add it to `.gitignore`.

---

## Module Sourcing

### SSH (recommended for local development)

```hcl
module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"
}
```

### HTTPS (for CI/CD environments like GitHub Actions)

```hcl
module "vcn" {
  source = "git::https://github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"
}
```

> **CI/CD Note:** For GitHub Actions, HTTPS works with public repos without additional config. For private repos, configure a `GIT_SSH_COMMAND` or use a deploy key.

### Source URL Anatomy

```
git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0
├── protocol ──────────────────────────────────────────────────┤├─ path ──┤├── tag ──┤
```

- `git::ssh://` — Protocol (uses system SSH keys)
- `//modules/vcn` — Subdirectory within the repository
- `?ref=v1.0.0` — Git ref (tag, branch, or commit SHA)

---

## Step-by-Step: Deploy a Landing Zone

### 1. Create Project Structure

```bash
mkdir -p my-infra && cd my-infra
```

### 2. Create `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.26"
    }
  }
}
```

### 3. Create `providers.tf`

```hcl
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
```

### 4. Create `variables.tf`

```hcl
variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key_path" { type = string }
variable "region" { type = string }
```

### 5. Create `main.tf`

```hcl
locals {
  tags = {
    project    = "my-project"
    managed_by = "terraform"
  }
}

module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "my-compartment"
  description           = "My project compartment"
  freeform_tags         = local.tags
}

module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"

  compartment_id  = module.compartment.id
  vcn_name        = "my-vcn"
  vcn_cidr_blocks = ["10.50.0.0/16"]
  vcn_dns_label   = "myvcn"
  freeform_tags   = local.tags
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

  freeform_tags = local.tags
}
```

### 6. Deploy

```bash
# Initialize (downloads modules from Git)
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# Verify
terraform output
terraform state list
```

### Expected Output

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

compartment_id = "ocid1.compartment.oc1..aaaa..."
vcn_id = "ocid1.vcn.oc1.sa-saopaulo-1..aaaa..."
public_subnet_id = "ocid1.subnet.oc1.sa-saopaulo-1..aaaa..."
private_subnet_id = "ocid1.subnet.oc1.sa-saopaulo-1..aaaa..."
```

---

## Version Pinning

### Why pin versions?

Without `?ref=`, Terraform uses the default branch (`main`). This means:

- A commit to `main` could **break** your infrastructure on next `terraform init`
- You lose **reproducibility** — same code can produce different results
- No **audit trail** of which module version is deployed

### Best Practice

```hcl
# ✅ Good — pinned to immutable tag
source = "git::ssh://...?ref=v1.0.0"

# ✅ Acceptable — pinned to commit SHA (most precise)
source = "git::ssh://...?ref=046056c"

# ⚠️ Risky — branch can change
source = "git::ssh://...?ref=main"

# ❌ Bad — no ref, follows HEAD
source = "git::ssh://..."
```

---

## Upgrading Modules

### 1. Check Available Versions

```bash
git -c 'versionsort.suffix=-' ls-remote --tags --sort='-v:refname' \
  git@github.com:andriocampos/terraform-oci-modules.git | head -5
```

### 2. Review CHANGELOG

Check [CHANGELOG.md](../CHANGELOG.md) for breaking changes between versions.

### 3. Update Source Reference

```hcl
# Before
source = "git::ssh://...?ref=v1.0.0"

# After
source = "git::ssh://...?ref=v1.1.0"
```

### 4. Re-initialize and Plan

```bash
# Download updated module
terraform init -upgrade

# Review changes (should show no resource changes for minor/patch bumps)
terraform plan
```

---

## Troubleshooting

### `Error: Failed to download module`

```
Error: Failed to download module "vcn"
Could not download module "vcn" source "git::ssh://..."
```

**Cause:** SSH key not configured or not added to GitHub.

**Fix:**
```bash
# Test SSH access
ssh -T git@github.com

# If it fails, add your key
ssh-add ~/.ssh/id_ed25519
```

---

### `Error: Unsupported attribute`

```
Error: Unsupported attribute
module.vcn.nonexistent_output
```

**Cause:** Module version doesn't have the referenced output.

**Fix:** Check the module's `outputs.tf` for the version you're using, or upgrade to a version that includes the output.

---

### `Error: Missing required argument`

```
Error: Missing required argument
The argument "vcn_cidr_blocks" is required, but no definition was found.
```

**Cause:** Required variable not provided.

**Fix:** Check the module's README for required inputs and add the missing variable.

---

### Terraform init is slow

**Cause:** Each module source triggers a separate `git clone`.

**Fix:** This is normal on first run. Subsequent runs use the cached version in `.terraform/modules/`. Run `terraform init -upgrade` only when you need to update module versions.

---

## Recommended `.gitignore`

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform.lock.hcl
crash.log

# OS
.DS_Store
```
