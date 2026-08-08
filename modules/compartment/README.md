# Módulo: Compartment

Cria um Compartment de Identidade OCI com suporte a controle de ciclo de vida.

## Uso

```hcl
module "compartment" {
  source = "git::ssh://git@github.com/andriocampos/terraform-oci-modules.git//modules/compartment?ref=v1.0.0"

  parent_compartment_id = var.tenancy_ocid
  name                  = "infraestrutura"
  description           = "Compartment de infraestrutura core"
  enable_delete         = true

  freeform_tags = {
    project    = "portfolio-sre"
    managed_by = "terraform"
  }
}
```

## Entradas

| Nome | Tipo | Obrigatório | Padrão | Descrição |
|------|------|:-----------:|--------|-----------|
| `parent_compartment_id` | `string` | ✅ | — | OCID do compartment pai (tipicamente `tenancy_ocid` para nível raiz) |
| `name` | `string` | ✅ | — | Nome de exibição do compartment |
| `description` | `string` | ❌ | `"Managed by Terraform"` | Descrição do compartment |
| `enable_delete` | `bool` | ❌ | `true` | Se o Terraform pode destruir este compartment |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Tags de formato livre |

## Saídas

| Nome | Tipo | Descrição |
|------|------|-----------|
| `id` | `string` | OCID do compartment criado |
| `name` | `string` | Nome de exibição do compartment |

## Recurso Criado

| Recurso | Referência |
|---------|------------|
| `oci_identity_compartment` | [Documentação](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_compartment) |

## Observações

- A criação de compartment é uma **operação IAM** — acontece no nível do tenancy independente da região.
- Após criação, aguarde **~30 segundos** para o compartment propagar antes de criar recursos dentro dele. O Terraform lida com isso implicitamente via grafo de dependências.
- Definir `enable_delete = false` previne que `terraform destroy` acidental remova o compartment e todos os recursos dentro dele.

## Custo

**Gratuito** — Compartments são uma estrutura de identidade sem billing associado.
