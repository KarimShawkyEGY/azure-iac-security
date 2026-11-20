# IaC Security Scan - Baseline Results

**Target:** `insecure/` (pre-remediation)
**Date:** 2026-11-20
**Tools:** Checkov, Trivy

## Summary

| Scanner | Passed | Failed | Total checks |
| :--- | ---: | ---: | ---: |
| Checkov | 10 | 24 | 34 |
| Trivy | - | 17 | - |

## Trivy findings by severity

| Severity | Count |
| :--- | ---: |
| Critical | 7 |
| High | 4 |
| Medium | 5 |
| Low | 1 |
| **Total** | **17** |

---

> **Baseline posture:** 24 Checkov policy failures and 11 high-or-critical Trivy findings across the Azure Terraform. These are remediated in `secure/`; see the post-fix results for the before/after comparison.

# IaC Security Scan - Results After Remediation

**Target:** `secure/` (post-remediation)
**Date:** 2026-11-20
**Tools:** Checkov, Trivy

## Summary

| Scanner | Passed | Failed | Total checks |
| :--- | ---: | ---: | ---: |
| Checkov | 17 | 17 | 34 |
| Trivy | - | 8 | - |

## Trivy findings by severity

| Severity | Count |
| :--- | ---: |
| Critical | 2 |
| High | 0 |
| Medium | 5 |
| Low | 1 |
| **Total** | **8** |

---

> **Improved posture:** 17 Checkov policy failures and 2 high-or-critical Trivy findings across the Azure Terraform. 7 Checkov policy failures and 9 high-or-critical Trivy findings were secured/patched
