# Terraform OCI Modules

Módulos Terraform reutilizáveis para Oracle Cloud Infrastructure (OCI).

## Módulos Disponíveis

| Módulo | Descrição | Recursos Criados |
|--------|-----------|------------------|
| [compartment](./modules/compartment/) | Compartment OCI | `oci_identity_compartment` |
| [vcn](./modules/vcn/) | VCN com networking completo | VCN, IGW, SGW, Route Tables, Security Lists |
| [subnets](./modules/subnets/) | Subnets pública e privada | `oci_core_subnet` (pub + pvt) |

## Uso

```hcl
module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Compartment base para infraestrutura"
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

  compartment_id  = module.compartment.id
  vcn_id          = module.vcn.vcn_id
  public_subnet_cidr  = "10.50.1.0/24"
  private_subnet_cidr = "10.50.11.0/24"

  route_table_public_id    = module.vcn.route_table_public_id
  route_table_private_id   = module.vcn.route_table_private_id
  security_list_public_id  = module.vcn.security_list_public_id
  security_list_private_id = module.vcn.security_list_private_id
}
```

## Versionamento

Usamos [Semantic Versioning](https://semver.org/):

- **MAJOR** — breaking changes (alteração de variáveis/outputs existentes)
- **MINOR** — novo módulo ou nova funcionalidade retrocompatível
- **PATCH** — bugfix ou melhoria na documentação

Sempre referencie uma tag específica (`?ref=v1.0.0`) para garantir estabilidade.

## Requisitos

| Requisito | Versão |
|-----------|--------|
| Terraform | >= 1.5.0 |
| Provider oracle/oci | ~> 8.26 |

## Exemplos

- [infra-core](./examples/infra-core/) — Exemplo completo de landing zone (compartment + VCN + subnets)

## Licença

MIT
