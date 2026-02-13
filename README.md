# oracle-cloud-vps

OCI (Oracle Cloud Infrastructure) standardization and replication across multiple accounts. This repository serves as the **Single Source of Truth (SSOT)** for all VPS instance configurations, network infrastructure, and deployment automation across 3 OCI tenancies.

## Repository Purpose

This repo enables consistent, repeatable infrastructure deployment across all OCI accounts while maximizing Always Free tier utilization. It combines:

- **Terraform** – Infrastructure as Code (IaC) definitions for VCNs, security, compute
- **Cloud-Init** – Per-instance bootstrap templates for OS configuration
- **Inventory** – JSON snapshots and documentation of deployed state per tenancy
- **Runbooks** – Step-by-step operational procedures and deployment guidance

## Key Principles

1. **SSOT**: This repo is the authoritative source. Any deviation requires documenting and updating here first.
2. **Automation-First**: Manual configuration is minimized; cloud-init and Terraform drive 95%+ of setup.
3. **Free-Tier Focused**: All instances, networks, and backups stay within Always Free boundaries.
4. **Standardized Naming**: Consistent naming schemes (amd1/arm1, amd2/arm2, amd3/arm3) across all accounts.
5. **Network Isolation**: Non-overlapping CIDRs per account (10.X.0.0/16 for VCNs, 172.2X.0.0/16 for Docker)
6. **Documentation**: Every change is documented in this repo before deployment.

## Repository Structure

```
oracle-cloud-vps/
├── README.md                      # This file
├── BASELINE.md                    # Gold-standard instance/account template
├── RUNBOOK.md                     # Operational procedures and deployment guide
├── iac/                           # Terraform modules and per-account configurations
│   ├── modules/
│   │   ├── network/               # VCN, subnets, route tables, NSGs
│   │   ├── compute/               # Instance definitions (amd/arm)
│   │   └── security/              # IAM policies, compartments
│   ├── tenancies/
│   │   ├── account1/              # Account 1 vars and root module
│   │   ├── account2/              # Account 2 vars and root module
│   │   └── account3/              # Account 3 vars and root module
│   └── variables.tf               # Global variable definitions
├── cloud-init/                    # Cloud-init user-data templates
│   ├── amd.yaml                   # AMD instance bootstrap (DNS/tunnels/utilities)
│   ├── arm.yaml                   # ARM instance bootstrap (databases/apps)
│   └── common.yaml                # Shared initialization logic
├── inventory/                     # State snapshots per account (not committed, reference only)
│   ├── account1/raw/              # Raw JSON exports from OCI CLI
│   ├── account2/raw/
│   ├── account3/raw/
│   ├── account1/summaries/        # Human-readable markdown docs
│   ├── account2/summaries/
│   └── account3/summaries/
└── docs/                          # Additional documentation
    ├── ARCHITECTURE.md            # High-level design and rationale
    ├── NETWORK-DESIGN.md          # CIDR plan, routing, DNS strategy
    └── TROUBLESHOOTING.md         # Common issues and fixes
```

## Quick Start

### For AI Assistants Using This Repo

**You must follow these rules:**

1. **Read this README and BASELINE.md first.** Understand the naming scheme and CIDR layout.
2. **Check RUNBOOK.md** before making any changes; it documents the intended workflows.
3. **Propose changes in plaintext discussion** before executing. Confirm with the owner (Alex).
4. **Update the repo** (this SSOT) before applying changes to live infrastructure.
5. **Never diverge from the baseline** without documenting why in a commit message and/or BASELINE.md.
6. **Inventory is read-only in Git**; snapshots are pushed from live tenancies via sync scripts, not committed manually.

### For Manual Deployment

1. Clone this repo: `git clone https://github.com/atnplex/oracle-cloud-vps.git`
2. Read `BASELINE.md` to understand the target state.
3. Review `iac/tenancies/<account>/` for your target account config.
4. Follow `RUNBOOK.md` for deployment steps.

## Account & Instance Naming

### Tenancies (Accounts)

- **account1** – Home region `${REGION_1}`, VCN `10.1.0.0/16`
- **account2** – Home region `${REGION_2}`, VCN `10.2.0.0/16`
- **account3** – Home region `${REGION_3}`, VCN `10.3.0.0/16`

### Instances

Each account has exactly 2 instances (for Always Free shape limits):

- **amdX** – VM.Standard.E2.1.Micro (1 OCPU AMD x86), DNS/tunnels role
- **armX** – VM.Standard.A1.Flex (up to 4 OCPU ARM), app/database role

Where X ∈ {1, 2, 3} matches the account number.

### Network CIDRs

- **VCN subnets**: `10.X.0.0/16` (X = account #)
  - Public subnet: `10.X.1.0/24`
  - Private subnet: `10.X.2.0/24`
- **Docker overlay networks**: `172.2X.0.0/16` (X = account #)
  - Default docker0 bridge: `172.2X.0.1/24`

This scheme prevents overlap and makes the account # immediately visible in any CIDR.

## Deployment Workflow

1. **Propose** – Discuss changes needed (new instance, network change, etc.)
2. **Document** – Update BASELINE.md or RUNBOOK.md with the change
3. **Code** – Write Terraform module or cloud-init template
4. **Test** – Deploy to sandbox/account3 first if available
5. **Audit** – Compare actual state to intended state
6. **Commit** – Push changes to main with clear commit message
7. **Replicate** – Apply same change to other accounts per runbook

## Inventory Sync

Inventory snapshots in `/inventory/accountX/raw/` are generated by automated collectors running in each OCI tenancy:

```bash
# Collector runs periodically on a small instance per tenancy
# Outputs JSON to Object Storage, then syncs to repo
oci compute instances list --compartment-id <ID> --all --output json > inventory.json
oci network vcns list --compartment-id <ID> --all --output json > vcns.json
# ... (more resources)
```

These are **read-only reference** and **not edited by hand**.

## Always Free Compliance

All infrastructure must fit within the OCI Always Free tier:

- **Compute**: 2 instances per account (1 AMD micro, 1 ARM flex)
- **VCN/Network**: 1 VCN per account, inclusive (subnets, gateways, etc.)
- **Block Storage**: 200 GB total per account (boot volumes + backup)
- **Object Storage**: 20 GB total per account
- **Outbound Data**: 1 TB/month per account

See `docs/ARCHITECTURE.md` for current utilization tracking.

## Contributing / Changing Config

If you need to modify infrastructure:

1. **Create a branch**: `git checkout -b <descriptive-name>`
2. **Update BASELINE.md or Terraform** (or both)
3. **Commit with clear message**: `git commit -m "Add X to account Y because Z"`
4. **Create a PR** for review before merging
5. **Merge to main** once approved
6. **Deploy** following the RUNBOOK

## Security Notes

- **This repo is PRIVATE.** Network CIDRs and deployment topology are sensitive.
- Do not commit OCI API keys, user passwords, or tenancy OCIDs directly (use `.tfvars` files and `.gitignore`).
- Inventory files may contain resource IDs; sanitize before sharing.

## Questions / Support

For setup questions or runbook clarifications, refer to:

1. **BASELINE.md** – The target state for a single account
2. **RUNBOOK.md** – Step-by-step procedures
3. **docs/** – Deep dives on architecture, networking, and troubleshooting

---

**Last updated**: 2025-02-13  
**Maintained by**: Alex (atnplex org)
