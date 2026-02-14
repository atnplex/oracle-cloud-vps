# Account 3 Deployment Preparation Checklist

**Date:** 2026-02-13  
**Agent:** comet-atnp1 (@atngit2)  
**Status:** READ-ONLY INVENTORY COMPLETE - AWAITING APPROVAL FOR DEPLOYMENT

## Inventory Status

✅ **COMPLETE**: Full OCI inventory collected via Cloud Shell  
✅ **UPLOADED**: All JSON files pushed to `inventory/account3/raw/`  
✅ **SUMMARY**: Preliminary summary created in `inventory/account3/summaries/ACCOUNT3-SUMMARY.md`

## Key Discovery

**Account 3 is a fresh/empty tenancy** with no compute instances deployed. This is IDEAL for clean baseline deployment.

## Deployment Delta Analysis

### Current State → Target State (BASELINE.md)

| Resource | Current | Target (BASELINE) | Action Required |
|----------|---------|-------------------|------------------|
| **Compartments** | Default only | network, workloads, security, shared, sandbox | CREATE 5 compartments |
| **VCN** | TBD/Default | 10.3.0.0/16 | CREATE or MODIFY |
| **Public Subnet** | None | 10.3.1.0/24 | CREATE |
| **Private Subnet** | None | 10.3.2.0/24 | CREATE |
| **Internet Gateway** | None/Default | 1 attached to VCN | CREATE |
| **NAT Gateway** | None | 1 for private subnet | CREATE |
| **Security Lists** | Default only | Custom per BASELINE | CREATE/MODIFY |
| **amd3 Instance** | NOT FOUND | VM.Standard.E2.1.Micro | CREATE |
| **arm3 Instance** | NOT FOUND | VM.Standard.A1.Flex | CREATE |
| **IAM Policies** | Default | Custom compartment policies | CREATE |
| **Dynamic Groups** | None | For instance principals | CREATE |

## Step-by-Step Remediation Plan

### [APPROVAL REQUIRED] Phase 1: Network Foundation

1. **Create Compartment Structure**
   - Create compartment: `network` (for VCN, subnets, gateways)
   - Create compartment: `workloads` (for compute instances)
   - Create compartment: `security` (for IAM, policies)
   - Create compartment: `shared` (optional - shared resources)
   - Create compartment: `sandbox` (optional - testing)

2. **Create VCN** (in `network` compartment)
   - CIDR: 10.3.0.0/16
   - Name: `vcn-account3` or per naming standard
   - DNS Label: `vcnacct3`

3. **Create Subnets**
   - Public Subnet: 10.3.1.0/24 (in `network` compartment)
   - Private Subnet: 10.3.2.0/24 (in `network` compartment)

4. **Create Gateways**
   - Internet Gateway: Attach to VCN
   - NAT Gateway: Attach to VCN (for private subnet outbound)

5. **Configure Route Tables**
   - Public route table: 0.0.0.0/0 → Internet Gateway
   - Private route table: 0.0.0.0/0 → NAT Gateway

6. **Create Security Lists**
   - Public subnet security list (per BASELINE: SSH, DNS ingress)
   - Private subnet security list (per BASELINE: SSH from amd3, database ports)

### [APPROVAL REQUIRED] Phase 2: IAM & Security

7. **Create IAM Policies**
   - Instance principal policies for compartments
   - Operator group policies
   - Developer read-only policies

8. **Create Dynamic Groups**
   - For instance principals in `workloads` compartment

### [APPROVAL REQUIRED] Phase 3: Compute Instances

9. **Deploy amd3 Instance**
   - Shape: VM.Standard.E2.1.Micro
   - Subnet: Public (10.3.1.0/24)
   - OS: Ubuntu 24.04 LTS Minimal
   - Boot volume: 50 GB
   - Cloud-init: Use `cloud-init/amd.yaml` template
   - Assign reserved public IP
   - Install: Tailscale, AdGuard, Cloudflared, Vector

10. **Deploy arm3 Instance**
    - Shape: VM.Standard.A1.Flex (2-4 OCPU, 12-24 GB RAM)
    - Subnet: Private (10.3.2.0/24)
    - OS: Ubuntu 24.04 LTS Minimal
    - Boot volume: 50 GB
    - Cloud-init: Use `cloud-init/arm.yaml` template
    - No public IP (access via amd3 or Tailscale)
    - Install: Docker, Tailscale, database tools

### [APPROVAL REQUIRED] Phase 4: Services Configuration

11. **Configure amd3 Services**
    - AdGuard Home: Listen on :53, configure upstreams
    - Cloudflare Tunnel: Set up ingress rules
    - Tailscale: Enable subnet routes (10.3.0.0/16, 172.23.0.0/16)
    - Vector: Configure log forwarding

12. **Configure arm3 Services**
    - Docker: Set bridge network to 172.23.0.0/16
    - Deploy containerized workloads per requirements

### Phase 5: Validation

13. **Run Validation Checklist** (from BASELINE.md)
    - ☐ Compartments exist and named correctly
    - ☐ VCN CIDR is 10.3.0.0/16
    - ☐ Subnets configured correctly
    - ☐ Gateways attached
    - ☐ Security lists applied
    - ☐ amd3 running with correct shape
    - ☐ arm3 running with correct shape
    - ☐ Tailscale connected on both
    - ☐ Docker working on both
    - ☐ AdGuard responding on amd3:53
    - ☐ Cloudflared tunnel active on amd3
    - ☐ arm3 can reach amd3 DNS
    - ☐ Inventory updated post-deployment

## Deployment Methods

### Option 1: Terraform (RECOMMENDED)
- Use modules in `/iac/tenancies/account3/`
- Apply in stages: network → IAM → compute
- State file management per RUNBOOK.md

### Option 2: Manual via OCI Console
- Follow step-by-step plan above
- Document all OCIDs in tracking sheet
- More error-prone, not recommended

### Option 3: OCI CLI Scripts
- Automate via bash + OCI CLI
- Good for repeatability
- Requires careful error handling

## Pre-Deployment Verification

- [ ] Reviewed BASELINE.md thoroughly
- [ ] Reviewed RUNBOOK.md deployment procedures
- [ ] Confirmed Always Free tier limits
- [ ] Prepared cloud-init templates
- [ ] Owner approval obtained
- [ ] Backup/rollback plan documented

## Post-Deployment Tasks

- [ ] Run full inventory again
- [ ] Update ACCOUNT3-SUMMARY.md with deployed state
- [ ] Compare deployed vs. BASELINE - document any deviations
- [ ] Test all services (DNS, tunnels, Docker, Tailscale)
- [ ] Document any issues encountered
- [ ] Update COLLABORATION.md checklist

## Risk Assessment

**Risk Level:** LOW  
**Rationale:** Fresh account with no existing infrastructure to disrupt

**Potential Issues:**
- Always Free tier capacity limits (especially ARM shapes)
- Region availability (us-sanjose-1)
- Cloud-init failures requiring manual intervention

## Approval Status

- [ ] Owner review of this deployment plan
- [ ] Approval to proceed with Phase 1 (Network)
- [ ] Approval to proceed with Phase 2 (IAM)
- [ ] Approval to proceed with Phase 3 (Compute)
- [ ] Approval to proceed with Phase 4 (Services)

---

**⚠️ CRITICAL:** Do NOT execute any deployment steps without explicit owner approval. This is a READ-ONLY inventory task.

**Next Step:** Create Pull Request for review.
