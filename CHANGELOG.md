# Changelog

Todas as alterações relevantes neste projeto serão documentadas aqui.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [1.0.0] - 2026-08-07

### Adicionado

- Módulo `compartment` — cria `oci_identity_compartment` com suporte a tags e controle de ciclo de vida
- Módulo `vcn` — cria VCN completa com:
  - Internet Gateway (IGW)
  - Service Gateway (SGW) para All OCI Services
  - Route Table pública (0.0.0.0/0 → IGW)
  - Route Table privada (OCI Services → SGW)
  - Security List pública (SSH 22 any, ICMP)
  - Security List privada (SSH 22 VCN-only, ICMP)
- Módulo `subnets` — cria subnet pública e privada com associação de RT e SL
- Exemplo completo `infra-core`
- Documentação completa com guia de uso e troubleshooting
