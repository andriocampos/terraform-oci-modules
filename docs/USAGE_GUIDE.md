# Guia de Uso

Guia completo para consumir os módulos deste repositório em seus projetos Terraform.

---

## Índice

- [Pré-requisitos](#pré-requisitos)
- [Configuração de Autenticação](#configuração-de-autenticação)
- [Sourcing de Módulos](#sourcing-de-módulos)
- [Passo-a-Passo: Deploy de Landing Zone](#passo-a-passo-deploy-de-landing-zone)
- [Versionamento e Pinagem](#versionamento-e-pinagem)
- [Atualizando Módulos](#atualizando-módulos)
- [Troubleshooting](#troubleshooting)

---

## Pré-requisitos

| Ferramenta | Versão | Finalidade |
|------------|--------|-----------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 | Engine de IaC |
| [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) | Última | Geração de API key e config |
| Git | Última | Sourcing de módulos via SSH |
| Chave SSH | — | Acesso ao GitHub para fontes `git::ssh://` |

### Verificar Instalação

```bash
terraform version      # >= 1.5.0
oci --version          # qualquer
git --version          # qualquer
ssh -T git@github.com  # deve dizer "Hi <user>! You've successfully authenticated"
```

---

## Configuração de Autenticação

### 1. Gerar API Key da OCI

```bash
# Gerar par de chaves (caso não tenha)
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
chmod 600 ~/.oci/oci_api_key.pem
```

### 2. Upload da Chave Pública no Console OCI

1. Acesse **Perfil** → **API Keys** → **Add API Key**
2. Escolha **Paste Public Key**
3. Cole o conteúdo de `~/.oci/oci_api_key_public.pem`
4. Anote o **fingerprint** exibido após upload

### 3. Configurar `~/.oci/config`

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaa...
fingerprint=aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
key_file=~/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..aaaaaaa...
region=sa-saopaulo-1
```

### 4. Criar `terraform.tfvars`

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaa..."
user_ocid        = "ocid1.user.oc1..aaaaaaa..."
fingerprint      = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "sa-saopaulo-1"
```

> ⚠️ **Nunca commite `terraform.tfvars`** — adicione ao `.gitignore`.

---

## Sourcing de Módulos

### SSH (recomendado para desenvolvimento local)

```hcl
module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"
}
```

### HTTPS (para ambientes CI/CD como GitHub Actions)

```hcl
module "vcn" {
  source = "git::https://github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"
}
```

> **Nota CI/CD:** Para GitHub Actions, HTTPS funciona com repos públicos sem configuração adicional.

### Anatomia da URL de Source

```
git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0
├── protocolo ─────────────────────────────────────────────────┤├─ path ──┤├── tag ──┤
```

- `git::ssh://` — Protocolo (usa chaves SSH do sistema)
- `//modules/vcn` — Subdiretório dentro do repositório
- `?ref=v1.0.0` — Ref do Git (tag, branch ou commit SHA)

---

## Passo-a-Passo: Deploy de Landing Zone

### 1. Criar Estrutura do Projeto

```bash
mkdir -p minha-infra && cd minha-infra
```

### 2. Criar `versions.tf`

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

### 3. Criar `providers.tf`

```hcl
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
```

### 4. Criar `variables.tf`

```hcl
variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key_path" { type = string }
variable "region" { type = string }
```

### 5. Criar `main.tf`

```hcl
locals {
  tags = {
    project    = "meu-projeto"
    managed_by = "terraform"
  }
}

module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "meu-compartment"
  description           = "Compartment do meu projeto"
  freeform_tags         = local.tags
}

module "vcn" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/vcn?ref=v1.0.0"

  compartment_id  = module.compartment.id
  vcn_name        = "minha-vcn"
  vcn_cidr_blocks = ["10.50.0.0/16"]
  vcn_dns_label   = "minhavcn"
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
# Inicializar (baixa módulos do Git)
terraform init

# Visualizar alterações
terraform plan

# Aplicar
terraform apply

# Verificar
terraform output
terraform state list
```

### Saída Esperada

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

compartment_id = "ocid1.compartment.oc1..aaaa..."
vcn_id = "ocid1.vcn.oc1.sa-saopaulo-1..aaaa..."
public_subnet_id = "ocid1.subnet.oc1.sa-saopaulo-1..aaaa..."
private_subnet_id = "ocid1.subnet.oc1.sa-saopaulo-1..aaaa..."
```

---

## Versionamento e Pinagem

### Por que pinar versões?

Sem `?ref=`, o Terraform usa a branch padrão (`main`). Isso significa:

- Um commit em `main` pode **quebrar** sua infra no próximo `terraform init`
- Você perde **reprodutibilidade** — mesmo código pode gerar resultados diferentes
- Sem **rastreabilidade** de qual versão do módulo está deployada

### Boas Práticas

```hcl
# ✅ Bom — fixado em tag imutável
source = "git::ssh://...?ref=v1.0.0"

# ✅ Aceitável — fixado em commit SHA (mais preciso)
source = "git::ssh://...?ref=046056c"

# ⚠️ Arriscado — branch pode mudar
source = "git::ssh://...?ref=main"

# ❌ Ruim — sem ref, segue HEAD
source = "git::ssh://..."
```

---

## Atualizando Módulos

### 1. Verificar Versões Disponíveis

```bash
git -c 'versionsort.suffix=-' ls-remote --tags --sort='-v:refname' \
  git@github.com:andriocampos/terraform-oci-modules.git | head -5
```

### 2. Consultar CHANGELOG

Verifique o [CHANGELOG.md](../CHANGELOG.md) para breaking changes entre versões.

### 3. Atualizar Referência no Source

```hcl
# Antes
source = "git::ssh://...?ref=v1.0.0"

# Depois
source = "git::ssh://...?ref=v1.1.0"
```

### 4. Re-inicializar e Planejar

```bash
# Baixar módulo atualizado
terraform init -upgrade

# Revisar mudanças (não deve mostrar alterações para bumps minor/patch)
terraform plan
```

---

## Troubleshooting

### `Error: Failed to download module`

```
Error: Failed to download module "vcn"
Could not download module "vcn" source "git::ssh://..."
```

**Causa:** Chave SSH não configurada ou não adicionada ao GitHub.

**Solução:**
```bash
# Testar acesso SSH
ssh -T git@github.com

# Se falhar, adicionar sua chave
ssh-add ~/.ssh/id_ed25519
```

---

### `Error: Unsupported attribute`

```
Error: Unsupported attribute
module.vcn.output_inexistente
```

**Causa:** A versão do módulo não possui o output referenciado.

**Solução:** Verifique o `outputs.tf` do módulo para a versão que está usando, ou atualize para uma versão que inclua o output.

---

### `Error: Missing required argument`

```
Error: Missing required argument
The argument "vcn_cidr_blocks" is required, but no definition was found.
```

**Causa:** Variável obrigatória não fornecida.

**Solução:** Verifique o README do módulo para as entradas obrigatórias e adicione a variável faltante.

---

### Terraform init lento

**Causa:** Cada source de módulo dispara um `git clone` separado.

**Solução:** Isso é normal na primeira execução. Execuções seguintes usam o cache em `.terraform/modules/`. Execute `terraform init -upgrade` apenas quando precisar atualizar versões.

---

## `.gitignore` Recomendado

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
