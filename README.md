# Azure IaC Security Scanning Pipeline

[![IaC Security Scan](https://github.com/KarimShawkyEGY/azure-iac-security/actions/workflows/iac-scan.yml/badge.svg)](https://github.com/KarimShawkyEGY/azure-iac-security/actions/workflows/iac-scan.yml)

A hands-on DevSecOps project that detects, remediates, and prevents security misconfigurations in Azure infrastructure-as-code (Terraform). It scans a deliberately insecure Azure configuration with two industry-standard tools (**Checkov** and **Trivy**), fixes every finding, and enforces the checks automatically in CI with **GitHub Actions** — with results surfaced in GitHub's **Code Scanning** dashboard via SARIF.

> **Scope note:** This is static analysis of Terraform code. No infrastructure is ever deployed to Azure, so the project is completely free to run and reproduce, and carries zero cloud cost or risk.

---

## Table of contents

- [Why this project](#why-this-project)
- [How it works](#how-it-works)
- [Repository structure](#repository-structure)
- [Tools](#tools)
- [The vulnerable baseline](#the-vulnerable-baseline)
- [Results](#results)
- [Remediation](#remediation)
- [CI/CD pipeline](#cicd-pipeline)
- [Key insight: why two scanners](#key-insight-why-two-scanners)
- [Reproduce it locally](#reproduce-it-locally)
- [What this demonstrates](#what-this-demonstrates)
- [Limitations & next steps](#limitations--next-steps)
- [Author](#author)

---

## Why this project

Most cloud breaches trace back to simple misconfigurations — public storage, management ports exposed to the internet, databases open to any IP, weak transport encryption, or secrets committed to source control. The cheapest place to catch these is **before deployment**, in the infrastructure code itself.

This project demonstrates that "shift-left" workflow end to end: it takes an intentionally insecure Azure Terraform configuration, detects the problems with automated scanners, remediates them, and wires the scanners into a CI pipeline so insecure infrastructure can't be merged unnoticed.

## How it works

```
 Terraform (.tf)  ──►  Checkov  ──┐
                                  ├──►  SARIF  ──►  GitHub Code Scanning
 Terraform (.tf)  ──►  Trivy   ──┘                    (Security tab)
         │
         └──►  run on every push / pull request via GitHub Actions
```

1. Azure infrastructure is defined as Terraform in two variants: an insecure baseline and a remediated version.
2. Checkov and Trivy statically analyze the code against their policy libraries.
3. A GitHub Actions workflow runs both scanners on every push and pull request.
4. Each scanner uploads **SARIF** output, so findings appear inline (file + line) in the repository's **Security → Code scanning** tab.

## Repository structure

```
azure-iac-security/
├── .github/
│   └── workflows/
│       └── iac-scan.yml            # CI pipeline: Checkov + Trivy, SARIF upload
├── insecure/
│   └── main.tf                     # deliberately misconfigured Azure baseline
├── secure/
│   ├── main.tf                     # remediated configuration
│   └── variables.tf                # sensitive values moved out of code
├── reports/
│   ├── checkov-baseline.txt        # Checkov scan, before remediation
│   ├── checkov-secure.txt          # Checkov scan, after remediation
│   ├── trivy-baseline.txt          # Trivy scan, before remediation
│   ├── trivy-secure.txt            # Trivy scan, after remediation
│   ├── failed-checks(Checkov).txt  # full list of failed Checkov checks
│   └── Check-Results.md            # summary of scan results
├── docs/
│   ├── findings.md                 # findings table mapped to CIS Azure controls
│   └── screenshots/                # evidence (scans, Actions run, code scanning)
│       ├── Failed-Checks.png
│       ├── Workflow-Success.png
│       └── Code-Scanning-Results.png
├── .gitignore
└── README.md
```

## Tools

| Tool | Role | Notes |
| :--- | :--- | :--- |
| [Checkov](https://www.checkov.io/) | IaC static analysis | 1,000+ policies, including graph-based checks |
| [Trivy](https://trivy.dev/) | IaC misconfiguration scanner | Aqua Security's scanner; absorbed the now-deprecated `tfsec` |
| [Terraform](https://www.terraform.io/) | Infrastructure as code | Azure provider (`azurerm`) |
| [GitHub Actions](https://docs.github.com/actions) | CI/CD | Runs scans and publishes SARIF |
| GitHub Code Scanning | Results dashboard | Inline, file/line findings in the Security tab |

## The vulnerable baseline

`insecure/main.tf` intentionally contains common, high-impact Azure misconfigurations:

- **Storage account** — public blob access enabled, plain HTTP allowed, and a weak minimum TLS version (1.0).
- **Network security group** — SSH (22) and RDP (3389) open to the entire internet (`0.0.0.0/0`).
- **SQL server** — a hardcoded administrator password (a secret in source control) and a firewall rule spanning `0.0.0.0`–`255.255.255.255` (the whole internet).
- **Key Vault** — purge protection disabled and public network access enabled.

## Results

Scans of the baseline (`insecure/`) vs. the remediated code (`secure/`):

| Scanner | Baseline failures | After remediation |
| :--- | ---: | ---: |
| Checkov | 24 | _see `reports/checkov-secure.txt`_ |
| Trivy   | 17 | _see `reports/trivy-secure.txt`_ |

Trivy severity breakdown (baseline): **7 Critical · 4 High · 5 Medium · 1 Low**.

The deliberately introduced, high-impact issues are driven to zero in the remediated version. A handful of lower-priority, defense-in-depth findings (logging, private endpoints, customer-managed keys, auditing) remain and are documented as accepted/optional in [`docs/findings.md`](docs/findings.md) — a realistic security review rarely ends at zero, and documenting that judgement is part of the work.

## Remediation

`secure/` fixes every planted issue:

| Area | Fix applied |
| :--- | :--- |
| Storage | Disabled public access, enforced HTTPS-only, set minimum TLS to 1.2 |
| Networking | Restricted SSH to a single admin IP; removed internet-facing RDP |
| Database | Narrowed the SQL firewall; moved the admin password to a `sensitive` variable; enforced TLS 1.2 |
| Key Vault | Enabled purge protection; disabled public network access |

A full line-by-line mapping of each finding to its scanner ID, CIS Azure control area, and fix is in [`docs/findings.md`](docs/findings.md).

## CI/CD pipeline

[`.github/workflows/iac-scan.yml`](.github/workflows/iac-scan.yml) runs on every push to `main` and every pull request:

- Runs **Checkov** and **Trivy** as parallel jobs.
- Uploads each scanner's **SARIF** output to GitHub, so findings appear in **Security → Code scanning** with file and line annotations.
- Can be switched from report-only (`soft_fail: true`) to a hard gate (`soft_fail: false`) so that a pull request introducing a new misconfiguration **fails the build and cannot be merged** — the core "shift-left" control.

## Key insight: why two scanners

The scanners did not agree, and that is the point. Checkov **passed** the SSH and RDP restriction checks even though the baseline NSG opened ports 22 and 3389 to `0.0.0.0/0` — **Trivy caught this as Critical** (AZU-0047/0048/0050). Conversely, Checkov flagged deeper configuration items (private endpoints, SAS expiration, Shared Key auth, Azure AD authentication) that Trivy did not.

Running both tools together gives materially better coverage than either alone. Relying on a single scanner would have missed either the most dangerous exposure or the deeper hardening gaps.

## Reproduce it locally

No Azure account needed — this is static analysis only.

```bash
# Prerequisites: Checkov and Trivy installed
# Checkov:  pipx install checkov
# Trivy:    install the release .deb / binary from github.com/aquasecurity/trivy

git clone https://github.com/KarimShawkyEGY/azure-iac-security.git
cd azure-iac-security

# Scan the insecure baseline
checkov -d insecure/
trivy config insecure/

# Scan the remediated version
checkov -d secure/
trivy config secure/
```

## What this demonstrates

- Reading cloud infrastructure-as-code and identifying real-world misconfigurations.
- Mapping findings to the **CIS Microsoft Azure Foundations Benchmark**.
- Hands-on use of the standard IaC scanners security teams actually run (Checkov, Trivy).
- **DevSecOps**: integrating security into CI/CD with GitHub Actions, SARIF, and code scanning, including a merge-blocking gate.
- Secure-by-design remediation and documented risk acceptance.
- Supply-chain awareness (pinning tool and action versions).

## Limitations & next steps

- **Static analysis only.** This project evaluates infrastructure *code* and does not assess a running Azure environment. The complementary approach is **Cloud Security Posture Management (CSPM)** — scanning a live cloud account for drift and runtime misconfiguration.
- **Possible extensions:** add a secrets-scanning step; extend coverage to Dockerfiles and Kubernetes manifests (both scanners support them); pin GitHub Actions to commit SHAs for supply-chain hardening; add a CSPM project against a live (free-tier) Azure subscription.

## Author

**[KarimShawkyEGY](https://github.com/KarimShawkyEGY)** — built as a hands-on cloud security / DevSecOps portfolio project.
