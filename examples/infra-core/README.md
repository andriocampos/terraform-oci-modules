# Exemplo: Infra Core (Landing Zone)

Este exemplo demonstra como usar todos os módulos para criar uma infraestrutura base na OCI.

## Uso

```bash
cd examples/infra-core
cp terraform.tfvars.example terraform.tfvars
# Preencha terraform.tfvars com seus OCIDs
terraform init
terraform plan
terraform apply
```

## Recursos criados

- 1 Compartment
- 1 VCN (10.50.0.0/16)
- 1 Internet Gateway
- 1 Service Gateway
- 2 Route Tables
- 2 Security Lists
- 2 Subnets (pública + privada)
