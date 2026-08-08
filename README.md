<p align="center">
  <img src="https://img.shields.io/badge/OCI-Oracle_Cloud-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="OCI"/>
  <img src="https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/>
  <img src="https://img.shields.io/github/v/tag/andriocampos/terraform-oci-modules?style=for-the-badge&label=vers%C3%A3o&color=blue" alt="Versão"/>
  <img src="https://img.shields.io/github/license/andriocampos/terraform-oci-modules?style=for-the-badge" alt="Licença"/>
</p>

# Terraform OCI Modules

Módulos Terraform reutilizáveis e prontos para produção para Oracle Cloud Infrastructure (OCI). Projetados para composabilidade, idempotência e compatibilidade com Free Tier.

---

## Visão Geral

Este repositório fornece um conjunto de módulos Terraform para provisionamento de recursos de rede e identidade na OCI. Cada módulo segue o [padrão de módulos Terraform](https://developer.hashicorp.com/terraform/language/modules/develop/structure) e é versionado independentemente via tags Git.

### Princípios de Design

- **Blast radius mínimo** — cada módulo gerencia uma única responsabilidade
- **Free Tier primeiro** — configurações padrão permanecem dentro dos limites gratuitos da OCI
- **Pin e esqueça** — consumidores referenciam uma tag `?ref=vX.Y.Z` para estabilidade
- **Zero secrets no código** — todos os valores sensíveis são injetados via variáveis

---

## Módulos

| Módulo | Descrição | Recursos |
|--------|-----------|----------|
| [`compartment`](./modules/compartment/) | Compartment de identidade com controle de ciclo de vida | `oci_identity_compartment` |
| [`vcn`](./modules/vcn/) | Stack completo de rede | VCN, IGW, SGW, Route Tables, Security Lists |
| [`subnets`](./modules/subnets/) | Subnets pública + privada | `oci_core_subnet` × 2 |

---

## Início Rápido

```hcl
module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Compartment de infraestrutura core"
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

## Topologia de Rede

```
┌─────────────────────────────────────────────────┐
│ VCN                                             │
│                                                 │
│  ┌─────────────┐         ┌─────────────┐       │
│  │ RT Pública  │         │ RT Privada  │       │
│  │ 0.0.0.0/0→IGW│        │ OCI Svc→SGW │       │
│  └──────┬──────┘         └──────┬──────┘       │
│         │                       │               │
│  ┌──────▼──────┐         ┌──────▼──────┐       │
│  │ SL Pública  │         │ SL Privada  │       │
│  │ SSH: any    │         │ SSH: VCN    │       │
│  └─────────────┘         └─────────────┘       │
│                                                 │
│  ┌─────────┐  ┌─────────┐                      │
│  │   IGW   │  │   SGW   │                      │
│  └────┬────┘  └────┬────┘                      │
└───────┼─────────────┼──────────────────────────-┘
        │             │
    Internet      Serviços OCI
```

---

## Requisitos

| Dependência | Versão |
|-------------|--------|
| Terraform | `>= 1.5.0` |
| Provider `oracle/oci` | `~> 8.26` |
| Git (acesso SSH) | Para sourcing dos módulos |

---

## Versionamento

Este projeto segue o [Versionamento Semântico 2.0.0](https://semver.org/lang/pt-BR/):

| Bump | Quando |
|------|--------|
| **MAJOR** | Mudanças incompatíveis em variáveis ou outputs existentes |
| **MINOR** | Novos módulos ou funcionalidades retrocompatíveis |
| **PATCH** | Correções de bugs ou documentação |

Sempre fixe uma tag específica no source:

```hcl
source = "git::ssh://...?ref=v1.0.0"  # ✅ fixado
source = "git::ssh://..."              # ❌ instável (segue HEAD)
```

---

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [Guia de Uso](./docs/USAGE_GUIDE.md) | Guia completo: pré-requisitos, autenticação, deploy passo-a-passo, versionamento, troubleshooting |
| [Módulo: compartment](./modules/compartment/README.md) | Entradas, saídas, notas |
| [Módulo: vcn](./modules/vcn/README.md) | Entradas, saídas, arquitetura, regras de segurança |
| [Módulo: subnets](./modules/subnets/README.md) | Entradas, saídas, planejamento CIDR, comportamento pub vs pvt |

## Exemplos

| Exemplo | Descrição |
|---------|-----------|
| [infra-core](./examples/infra-core/) | Landing zone completa: compartment + VCN + subnets |

---

## Contribuindo

1. Crie uma branch a partir de `main`
2. Faça alterações seguindo os padrões existentes
3. Execute `terraform fmt -recursive` e `terraform validate`
4. Atualize o `CHANGELOG.md`
5. Abra um Pull Request

---

## Licença

[MIT](./LICENSE)
