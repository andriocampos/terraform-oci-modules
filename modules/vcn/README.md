# Módulo: VCN

Cria um stack completo de rede OCI incluindo gateways, route tables e security lists. Fornece uma base de rede pronta para produção com separação pública/privada.

## Uso

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

## Entradas

| Nome | Tipo | Obrigatório | Padrão | Descrição |
|------|------|:-----------:|--------|-----------|
| `compartment_id` | `string` | ✅ | — | OCID do compartment onde a VCN será criada |
| `vcn_name` | `string` | ✅ | — | Nome de exibição da VCN |
| `vcn_cidr_blocks` | `list(string)` | ✅ | — | Blocos CIDR da VCN (ex: `["10.50.0.0/16"]`) |
| `vcn_dns_label` | `string` | ✅ | — | Label DNS da VCN (máx 15 chars, alfanumérico, iniciar com letra) |
| `igw_display_name` | `string` | ❌ | `"igw-core"` | Nome do Internet Gateway |
| `sgw_display_name` | `string` | ❌ | `"sgw-core"` | Nome do Service Gateway |
| `freeform_tags` | `map(string)` | ❌ | `{}` | Tags de formato livre aplicadas a todos os recursos |

## Saídas

| Nome | Tipo | Descrição |
|------|------|-----------|
| `vcn_id` | `string` | OCID da VCN |
| `igw_id` | `string` | OCID do Internet Gateway |
| `sgw_id` | `string` | OCID do Service Gateway |
| `route_table_public_id` | `string` | OCID da Route Table pública |
| `route_table_private_id` | `string` | OCID da Route Table privada |
| `security_list_public_id` | `string` | OCID da Security List pública |
| `security_list_private_id` | `string` | OCID da Security List privada |

## Recursos Criados

| Recurso | Nome | Propósito |
|---------|------|-----------|
| `oci_core_vcn` | `{vcn_name}` | Rede Virtual Cloud |
| `oci_core_internet_gateway` | `igw-core` | Acesso à internet (bidirecional) |
| `oci_core_service_gateway` | `sgw-core` | Acesso a serviços OCI sem NAT |
| `oci_core_route_table` | `rt-pub-core` | Rotas para subnet pública (0.0.0.0/0 → IGW) |
| `oci_core_route_table` | `rt-pvt-core` | Rotas para subnet privada (Serviços OCI → SGW) |
| `oci_core_security_list` | `sl-pub-core` | Regras de firewall para subnet pública |
| `oci_core_security_list` | `sl-pvt-core` | Regras de firewall para subnet privada |

## Arquitetura

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
│  │(internet)│  │(svc OCI) │                            │
│  └────┬─────┘  └────┬─────┘                            │
└───────┼──────────────┼─────────────────────────────────-┘
        │              │
    Internet      Serviços OCI (repos, storage, registry)
```

## Regras das Security Lists

### Pública (`sl-pub-core`)

| Direção | Protocolo | Porta/Tipo | Origem/Destino | Descrição |
|---------|-----------|------------|----------------|-----------|
| Ingress | TCP | 22 | `0.0.0.0/0` | SSH de qualquer origem |
| Ingress | ICMP | Tipo 3, Código 4 | `0.0.0.0/0` | Path MTU Discovery |
| Ingress | ICMP | Tipo 3 | CIDR da VCN | Destination Unreachable |
| Egress | ALL | — | `0.0.0.0/0` | Permitir toda saída |

### Privada (`sl-pvt-core`)

| Direção | Protocolo | Porta/Tipo | Origem/Destino | Descrição |
|---------|-----------|------------|----------------|-----------|
| Ingress | TCP | 22 | CIDR da VCN | SSH somente da VCN |
| Ingress | ICMP | Tipo 3, Código 4 | CIDR da VCN | Path MTU Discovery |
| Egress | ALL | — | `0.0.0.0/0` | Permitir toda saída |

## Decisões de Design

| Decisão | Justificativa |
|---------|---------------|
| Service Gateway em vez de NAT Gateway | NAT GW custa ~R$85/mês. SGW é gratuito e dá acesso a repos OCI, Object Storage, Container Registry |
| SSH aberto para 0.0.0.0/0 na SL pública | Ambiente de portfólio/lab. Em produção, restringir a IPs conhecidos ou usar Bastion |
| Regras ICMP incluídas | Necessárias para Path MTU Discovery — sem elas, pacotes grandes são dropados silenciosamente |
| Regras stateful (padrão) | Simplifica gerenciamento — tráfego de resposta é automaticamente permitido |

## Custo

**Gratuito** — Todos os recursos criados por este módulo (VCN, IGW, SGW, Route Tables, Security Lists) estão incluídos no Free Tier da OCI.
