# Findings & Fixes — Azure IaC Security Scan

**Target:** `insecure/main.tf` (baseline, pre-remediation)
**Date:** 2026-11-20
**Tools:** Checkov, Trivy

## Scan totals

| Scanner | Passed | Failed | Severity breakdown |
| :--- | ---: | ---: | :--- |
| Checkov | 10 | 24 | — |
| Trivy | — | 17 | 7 Critical · 4 High · 5 Medium · 1 Low |

## Core findings (deliberately introduced, remediated in `secure/`)

| Finding | Resource | Scanner / ID | CIS Azure Control | Fix |
| ------- | -------- | ------------ | ----------------- | --- |
| Public blob access | storage account | Checkov / CKV_AZURE_190 | Storage | Set Public Access False |
| No HTTPS enforcement | storage account | Trivy / AZU-0008 | Storage | Set `https_traffic_only_enabled = true` |
| Insecure TLS version (1.0) | storage account | Checkov / CKV_AZURE_44 · Trivy / AZU-0011 | Storage | Set `min_tls_version = "TLS1_2"` |
| SSH open to internet (0.0.0.0/0) | NSG | Trivy / AZU-0050 | Networking | Restrict `source_address_prefix` to admin IP |
| RDP open to internet (0.0.0.0/0) | NSG | Trivy / AZU-0048 | Networking | Remove rule or restrict to admin IP |
| SQL firewall allows all IPs | SQL firewall rule | Checkov / CKV_AZURE_11 · Trivy / AZU-0029 | Database | Narrow start/end IP range |
| SQL public network access | SQL server | Checkov / CKV_AZURE_113 · Trivy / AZU-0022 | Database | Disable public network access |
| SQL weak TLS | SQL server | Checkov / CKV_AZURE_52 | Database | Set `minimum_tls_version = "1.2"` |
| Hardcoded admin password | SQL server | Checkov secrets † | Database | Move to sensitive variable |
| Key Vault purge protection off | key vault | Checkov / CKV_AZURE_110 · Trivy / AZU-0016 | Key Vault | Set `purge_protection_enabled = true` |
| Key Vault public network access | key vault | Checkov / CKV_AZURE_189 · Trivy / AZU-0013 | Key Vault | Set `public_network_access_enabled = false` |
| Key Vault not recoverable (soft delete) | key vault | Checkov / CKV_AZURE_42 | Key Vault | Enable soft delete / recovery |

† Not flagged by the Terraform misconfiguration scan — hardcoded secrets are detected by Checkov's separate *secrets* framework. Hardcoding credentials in IaC is still a critical issue; the fix is to move the value to a `sensitive` variable.

## Additional hardening findings (defense-in-depth)

These were also raised by the scanners. They go beyond the deliberately planted issues and represent further hardening. Some remain in `secure/` as accepted or lower-priority items — documenting that decision is part of a real review.

| Finding | Resource | Scanner / ID | CIS Azure Control | Recommended action |
| ------- | -------- | ------------ | ----------------- | ------------------ |
| Default network action allows access | storage account | Trivy / AZU-0012 | Storage | Set `default_action = "Deny"` in network rules |
| Logging not enabled | storage account | Checkov / CKV_AZURE_33 · Trivy / AZU-0057 | Storage | Enable Storage Analytics logging |
| No geo-redundant replication | storage account | Checkov / CKV_AZURE_206 · Trivy / AZU-0058 | Storage | Use GRS/RAGRS (lab uses LRS) |
| No infrastructure encryption | storage account | Trivy / AZU-0061 | Storage | Enable `infrastructure_encryption_enabled` |
| No customer-managed key | storage account | Checkov / CKV2_AZURE_1 | Storage | Encrypt with CMK (advanced) |
| No private endpoint | storage account | Checkov / CKV2_AZURE_33 | Storage | Add private endpoint (advanced) |
| No SAS expiration policy | storage account | Checkov / CKV2_AZURE_41 | Storage | Configure SAS expiry |
| Shared Key authorization allowed | storage account | Checkov / CKV2_AZURE_40 | Storage | Prefer Azure AD auth |
| Blob soft delete not enabled | storage account | Checkov / CKV2_AZURE_38 | Storage | Enable blob soft delete |
| Auditing not enabled | SQL server | Checkov / CKV_AZURE_23, CKV_AZURE_24 · Trivy / AZU-0027 | Database | Enable auditing, retention > 90 days |
| No Azure AD authentication | SQL server | Checkov / CKV2_AZURE_27 | Database | Configure AAD admin |
| Vulnerability Assessment not enabled | SQL server | Checkov / CKV2_AZURE_2 | Database | Enable VA with a storage account |
| No private endpoint | SQL server | Checkov / CKV2_AZURE_45 | Database | Add private endpoint (advanced) |
| No network ACL / firewall | key vault | Checkov / CKV_AZURE_109 · Trivy / AZU-0013 | Key Vault | Add `network_acls` with `default_action = "Deny"` |
| No private endpoint | key vault | Checkov / CKV2_AZURE_32 | Key Vault | Add private endpoint (advanced) |

## Scanner coverage note

The two scanners did **not** agree, which is exactly why both are worth running:

- Checkov **passed** the SSH and RDP restriction checks (CKV_AZURE_9, CKV_AZURE_10) despite the NSG opening ports 22 and 3389 to `0.0.0.0/0`. **Trivy caught this** as Critical (AZU-0047, AZU-0048, AZU-0050).
- Conversely, Checkov flagged several configuration-depth items (private endpoints, SAS policy, Shared Key auth, VA, AAD auth) that Trivy did not.

Running Checkov and Trivy together gives materially better coverage than either alone — relying on a single tool would have missed the most dangerous exposure (open SSH/RDP) or the deeper hardening gaps.
