# OCI Account 2 Infrastructure Inventory Summary

<!-- agent:comet-atnp3 --> @atngit2 Inventory collection completed for Account 2
<!-- reviewer:antigravity (fact-checked 2026-02-13) -->

**Tenancy:** wongkm1alex  
**Home Region:** US West (San Jose) - us-sanjose-1  
**Collection Date:** 2026-02-13 21:45 PST  
**Collected By:** comet-atnp3 (@atngit2)  
**Fact-Checked By:** Antigravity (2026-02-13 23:20 PST)  

## Executive Summary

READ-ONLY infrastructure inventory collected for OCI Account 2 (wongkm1alex tenancy). All 13 JSON resource exports collected via OCI CLI in Cloud Shell.

> [!IMPORTANT]
> **The original agent summary contained factual errors that contradicted the raw JSON data.** This version has been corrected by cross-referencing every claim against the committed JSON files.

## Key Infrastructure (Verified from Raw JSON)

### VCN Configuration

| Field | Value | Source |
|:------|:------|:-------|
| **VCN Name** | condo | `vcns.json` → `display-name` |
| **VCN CIDR** | **10.1.0.0/16** | `vcns.json` → `cidr-block` |
| **IPv6 CIDR** | 2603:c024:c013:e600::/56 | `vcns.json` → `ipv6-cidr-blocks` |
| **DNS Label** | condo | `vcns.json` → `dns-label` |
| **State** | AVAILABLE | `vcns.json` → `lifecycle-state` |

**Baseline Comparison:**
- Expected CIDR per BASELINE.md: `10.2.0.0/16`
- Actual CIDR: `10.1.0.0/16`
- **Deviation**: CIDR uses Account 1's range (`10.1.x.x`) instead of Account 2's (`10.2.x.x`)

### Compute Instances

| Field | Value | Source |
|:------|:------|:-------|
| **Instance Count** | **1** | `instances.json` → `data` array length |
| **Display Name** | condo | `instances.json` → `display-name` |
| **Shape** | **VM.Standard.A1.Flex** (ARM) | `instances.json` → `shape` |
| **OCPUs** | 4 | `instances.json` → `shape-config.ocpus` |
| **RAM** | 24 GB | `instances.json` → `shape-config.memory-in-gbs` |
| **Region** | us-sanjose-1 | `instances.json` → `region` |
| **State** | RUNNING | `instances.json` → `lifecycle-state` |
| **Created** | 2026-01-23T07:57:39 UTC | `instances.json` → `time-created` |

**Baseline Comparison:**
- Expected per BASELINE.md: 2 instances (`amd2` = VM.Standard.E2.1.Micro + `arm2` = VM.Standard.A1.Flex)
- Actual: 1× ARM flex instance (`condo`)
- **Missing**: AMD micro instance (VM.Standard.E2.1.Micro) — 0 found

### Subnets

| Subnet | CIDR | Type | IPv6 |
|:-------|:-----|:-----|:-----|
| public subnet-condo | 10.1.0.0/24 | Public | 2603:c024:c013:e600::/64 |
| private subnet-condo | 10.1.1.0/24 | Private | None |

### Security Highlights (from `security-lists.json`)

The default security list has well-configured rules:
- SSH (port 22) — open to 0.0.0.0/0 and ::/0
- **Tailscale** UDP 41641 — open for direct P2P (IPv4 + IPv6)
- **DNS** UDP/TCP 53 — restricted to `172.115.100.1/32` (home IP only, good practice)
- IPv6 ICMP — enabled for diagnostics

### Storage

| Resource | Details | Source |
|:---------|:--------|:-------|
| Boot Volume | 200 GB, `condo (Boot Volume)`, AVAILABLE | `boot-volumes.json` |
| Block Volumes | None | `volumes.json` (empty) |
| Buckets | None | `buckets.json` (empty) |

### IAM

| Resource | Details | Source |
|:---------|:--------|:-------|
| Policies | 1 policy: "Tenant Admin Policy" — `ALLOW GROUP Administrators to manage all-resources IN TENANCY` | `policies.json` |
| Compartments | Default structure | `compartments.json` (empty/default) |
| Dynamic Groups | None | `dynamic-groups.json` (empty) |

---

## Baseline Deviation Report (Fact-Checked)

| Resource | Baseline Target | Actual (from JSON) | Status |
|:---------|:---------------|:-------------------|:-------|
| **VCN CIDR** | 10.2.0.0/16 | 10.1.0.0/16 | ❌ DEVIATED (uses Account 1 range) |
| **Public Subnet** | 10.2.1.0/24 | 10.1.0.0/24 | ❌ DEVIATED |
| **Private Subnet** | 10.2.2.0/24 | 10.1.1.0/24 | ❌ DEVIATED |
| **ARM Instance** | VM.Standard.A1.Flex | ✅ condo (4 OCPU, 24 GB) | ✅ PRESENT |
| **AMD Instance** | VM.Standard.E2.1.Micro | Not found | ❌ MISSING |
| **Instance Count** | 2 | 1 | ❌ SHORT |
| **Boot Volume** | 50 GB | 200 GB | ⚠️ OVERSIZED |
| **Compartments** | 5 structured | Default only | ❌ MISSING |
| **Tailscale** | Required | Security rules present (UDP 41641) | ✅ CONFIGURED |
| **DNS** | Required | Security rules present (53 UDP/TCP) | ✅ CONFIGURED |

---

## Data Collection Summary

All 13 OCI resource inventory files collected:

| # | File | Status | Content |
|:-:|:-----|:-------|:--------|
| 1 | `boot-volumes.json` | ✅ | 1 boot volume (200 GB) |
| 2 | `buckets.json` | ✅ | Empty |
| 3 | `compartments.json` | ✅ | Empty/default |
| 4 | `dynamic-groups.json` | ✅ | Empty |
| 5 | `images.json` | ✅ | OCI images catalog (4,814 lines) |
| 6 | `instances.json` | ✅ | 1 ARM instance |
| 7 | `nsgs.json` | ✅ | Empty |
| 8 | `policies.json` | ✅ | 1 admin policy |
| 9 | `route-tables.json` | ✅ | 2 route tables |
| 10 | `security-lists.json` | ✅ | 2 security lists with Tailscale/DNS rules |
| 11 | `subnets.json` | ✅ | 2 subnets (public + private) |
| 12 | `vcns.json` | ✅ | 1 VCN (10.1.0.0/16) |
| 13 | `volumes.json` | ✅ | Empty |

---

## Corrections Log

| Original Claim | Correction | Evidence |
|:---------------|:-----------|:---------|
| "VCN CIDR 10.0.0.0/16" | **10.1.0.0/16** | `vcns.json` line: `"cidr-block": "10.1.0.0/16"` |
| "2 instances (both VM.Standard.E2.1.Micro)" | **1 instance (VM.Standard.A1.Flex, ARM)** | `instances.json` shows 1 entry with `"shape": "VM.Standard.A1.Flex"` |
| "Missing ARM flex instance" | **ARM instance IS present** — it's the AMD micro that's missing | `instances.json` → `shape-config.ocpus: 4.0` |

---

**Inventory Status:** ✅ COMPLETE (fact-checked)  
**Last Updated:** 2026-02-13 23:20 PST  
**Original Agent:** comet-atnp3  
**Reviewer:** Antigravity
