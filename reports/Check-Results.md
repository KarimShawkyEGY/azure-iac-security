# IaC Security Scan — Baseline Results

**Target:** `insecure/` (pre-remediation)
**Date:** 2026-11-20
**Tools:** Checkov, Trivy

## Summary

| Scanner | Passed | Failed | Total checks |
| :--- | ---: | ---: | ---: |
| Checkov | 6 | 14 | 20 |
| Trivy | — | 8 | 8 |

## Trivy findings by severity

| Severity | Count |
| :--- | ---: |
| Critical | 3 |
| High | 5 |
| **Total** | **8** |

---

> **Baseline posture:** 14 Checkov policy failures and 8 high-or-critical Trivy findings across the Azure Terraform. These are remediated in `secure/`; see the post-fix results for the before/after comparison.
