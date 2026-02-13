# BASELINE.md – Gold Standard Infrastructure

This document describes the **target state** for a single OCI account and its instances. All three accounts (1, 2, 3) must conform to this baseline.

## Account Structure (Per Tenancy)

### Compartments

Each account must have the following compartment structure:

```
Root
├── network         # VCN, subnets, NSGs, gateways
├── workloads       # Compute instances, backups
├── security        # IAM, policies, dynamic groups
├── shared          # Optional: shared resources (DNS, log aggregation)
└── sandbox         # Optional: testing and experimentation
```

**Rationale:** Compartments isolate resources for cleaner IAM policies, quotas, and cost tracking. Do not use Root compartment for workloads.

### IAM / Authentication

- **Instance Principal Auth:** All compute instances authenticate to OCI using instance principal credentials (no API keys embedded).
- **Groups:**
  - `<account>-admin` – Full tenancy access
  - `<account>-operators` – Network + compute read/write in workloads/network compartments
  - `<account>-developers` – Read-only across all compartments
- **Policies:**
  - Instance principals can read/write to compartments: `network`, `workloads`, `security`
  - No root compartment access from instances

## Network Baseline

### VCN & Subnets

**Per-account CIDR scheme:**

```
Account 1: 10.1.0.0/16
Account 2: 10.2.0.0/16
Account 3: 10.3.0.0/16
```

**Subnet layout (within each VCN):**

```
10.X.1.0/24    – Public subnet (amdX instance, 1 reserved IP for NAT gateway)
10.X.2.0/24    – Private subnet (armX instance)
10.X.255.0/24  – Reserved (future use or management)
```

**Route tables:**

- **Public subnet routes:**
  - Destination 0.0.0.0/0 → Internet Gateway
  - Destination 10.X.0.0/16 → Local VCN
- **Private subnet routes:**
  - Destination 10.X.0.0/16 → Local VCN
  - Destination 0.0.0.0/0 → NAT Gateway (optional, only if outbound internet needed)

**Internet Gateway & NAT:**

- 1 Internet Gateway per VCN (attached to public subnet)
- 1 NAT Gateway per VCN (attached to public subnet, used by private subnet for outbound-only access)

### Security Lists & NSGs

**Public subnet (amdX):**

- **Inbound:**
  - Port 53 (UDP/TCP) from allow-list of ISP/home IPs (DNS ingestion)
  - Port 22 (SSH) from Tailscale IP range (for management)
  - All other inbound: DENY
- **Outbound:**
  - All outbound to 0.0.0.0/0 (DNS queries, Cloudflare Tunnel, NTP, etc.)

**Private subnet (armX):**

- **Inbound:**
  - Port 22 (SSH) from amdX private IP (bastion pattern)
  - Port 3306 (MySQL) from amdX private IP (if using Galera)
  - Port 5432 (PostgreSQL) from amdX private IP (if using app)
  - All other inbound: DENY
- **Outbound:**
  - All to 0.0.0.0/0 (for package updates, external APIs, etc.)

### DNS Resolution

- **OCI-provided DNS resolver:** Use default (VCN-provided 8.8.8.8 or 1.1.1.1 inside VCN).
- **Custom DNS (AdGuard on amdX):** amdX runs AdGuard to provide ad-blocking and per-client rules.
  - amdX advertises itself as DNS server to armX via DHCP option set or static config.
  - External lookups: amdX forwards to public resolvers.
  - Allowed clients (hardened): `amdX`, `armX`, Tailscale gateway IP.

## Compute Baseline

### Instance Naming

- **amdX:** VM.Standard.E2.1.Micro (1 OCPU, 1 GB RAM)
  - Hostname: `amdX`
  - Display name (OCI): `amdX`
  - Subnet: Public (10.X.1.0/24)
  - Role: Gateway (DNS, tunnels, exit node)

- **armX:** VM.Standard.A1.Flex (2-4 OCPU, 12-24 GB RAM per Account tier)
  - Hostname: `armX`
  - Display name (OCI): `armX`
  - Subnet: Private (10.X.2.0/24)
  - Role: Compute/database workloads

Where X ∈ {1, 2, 3} matches the account number.

### Boot Volume

- **OS Image:** Ubuntu 24.04 LTS Minimal
- **Size:** 50 GB (fits Always Free, leaves room for snapshots)
- **Encryption:** OCI-managed key (default)
- **Backups:** Enabled, weekly schedule, 4-week retention

### Cloud-Init Bootstrap

Both instances are initialized with cloud-init user-data:

**Common (both instances):**

```yaml
- Create user 'alex' (UID 1114) with passwordless sudo
- Create group 'atn' (GID 1114)
- Create /atn directory (1114:1114, mode 0775)
- Configure SSH: only key-based auth, disable root login
- Install Tailscale (systemd service, subnet routing enabled on amdX)
- Install Docker (with user alex in docker group)
- Configure sysctl for security and performance
- Set hostname to amdX or armX
```

**amdX-specific:**

```yaml
- Install AdGuard Home (DNS filtering on :53)
- Install Cloudflared (Cloudflare Tunnel daemon)
- Install Vector (log aggregation agent)
- Install curl, jq, netcat-openbsd, htop (utility tools)
- Tailscale: enable subnet routing (routes 10.X.0.0/16 and 172.2X.0.0/16)
```

**armX-specific:**

```yaml
- Install Docker-compose
- Install MySQL/PostgreSQL client tools (for Galera participation or app connectivity)
- Install git, build-essential (for custom container builds if needed)
- Optionally: pull and start Docker services (databases, app stack)
```

### Networking on Instances

**amdX (public subnet):**

```
eth0: 10.X.1.Y (primary private IP)
      → Reserved public IP (static, assigned via OCI)
DNS: 169.254.169.254 (OCI metadata service) + custom (AdGuard on localhost)
Default route: IGW (0.0.0.0/0 via IGW)
```

**armX (private subnet):**

```
eth0: 10.X.2.Y (primary private IP)
DNS: 10.X.1.Y (amdX AdGuard) or OCI resolver
Default route: NAT GW (0.0.0.0/0 via NATGW) if outbound internet needed
```

### Docker Networking

**Docker bridge per account:**

```
Account 1: docker0 → 172.21.0.0/16
Account 2: docker0 → 172.22.0.0/16
Account 3: docker0 → 172.23.0.0/16
```

**Custom docker networks (per account):**

```yaml
# Created via docker network create
network_name: "atn-app"
driver: bridge
cidr: 172.2X.1.0/24  # X = account #
```

This ensures no CIDR overlap between accounts or with Docker defaults.

## Storage Baseline

### Block Storage

- **Boot volume:** 50 GB per instance (100 GB total per account)
- **Backups:** Enabled per account
  - Schedule: Weekly (e.g., Sunday 00:00 UTC)
  - Retention: 4 weeks (28 days)
  - Always Free allocation: 200 GB per account (sufficient for 2 x 50 GB boot + backups)

**No additional block volumes** unless workload demands it.

### Object Storage

- **Buckets:** 1 per account (or shared per organization decision)
- **Usage:** Inventory exports, log archives, config backups
- **Always Free allocation:** 20 GB per account

## Services & Agents Baseline

### amdX (Gateway Node)

- **Tailscale:** Running with subnet routes enabled
  - Routes: `10.X.0.0/16` (entire VCN), `172.2X.0.0/16` (docker)
  - Acts as exit node (optional, for routing outbound Internet traffic from armX)
  - MagicDNS: Enabled (for easy .ts domain access)

- **Cloudflared (Cloudflare Tunnel):**
  - Daemon service connecting to Cloudflare.
  - Ingress rules route inbound HTTP/HTTPS to docker services or localhost.
  - No public IPs exposed; all ingress via Cloudflare tunnel.

- **AdGuard Home:**
  - Listening on `:53` (UDP+TCP) for DNS queries.
  - Upstreams: `8.8.8.8`, `1.1.1.1` (public resolvers).
  - Allowed clients (hardened): `10.X.1.0/24` (public subnet) + `10.X.2.0/24` (private subnet).
  - Adlists: Enabled for common ad networks + malware.
  - Access log: Enabled, forwarded to Vector.

- **Vector (Log Aggregation):**
  - Collecting logs from `/var/log/syslog`, Docker containers, AdGuard.
  - Forwarding to centralized sink (Object Storage or external log service).
  - Format: JSON (easy parsing).

### armX (Compute Node)

- **Docker:** Running containerized workloads.
  - Services depend on deployment (Galera cluster, app stack, OpenWebUI, etc.).
  - All containers on custom bridge network (`atn-app`).

- **Tailscale:** Enabled for management access.
  - No subnet routing; only direct IP access.
  - Allows SSH management from amdX or external Tailscale peers.

- **No public IP:** All ingress via amdX tunnel or Tailscale.

## Compliance & Quotas

### Always Free Limits (per account)

- **Compute:** 2 instances (amdX micro + armX flex) ✓
- **VCN/Networking:** 1 VCN with subnets, gateways, NSGs ✓
- **Block Storage:** 200 GB (boot + backups) – Current: ~120 GB ✓
- **Object Storage:** 20 GB – Current: TBD (expect <5 GB)
- **Outbound Data:** 1 TB/month – Current: TBD (expect <50 GB/month)

**Status:** All accounts within Always Free tier.

## Validation Checklist

When deploying or updating an account, validate:

- [ ] Compartments exist and are named correctly
- [ ] VCN CIDR is correct per account (10.X.0.0/16)
- [ ] Public subnet exists (10.X.1.0/24), private subnet exists (10.X.2.0/24)
- [ ] Internet Gateway attached to public subnet
- [ ] NAT Gateway attached to public subnet
- [ ] Security lists/NSGs applied correctly (inbound DNS on amdX, SSH on both)
- [ ] amdX instance exists, running, has reserved public IP
- [ ] armX instance exists, running, in private subnet
- [ ] Both instances have correct hostname (amdX/armX)
- [ ] Cloud-init bootstrap has completed (check /var/log/cloud-init-output.log)
- [ ] Tailscale is running and connected
- [ ] Docker is installed and working
- [ ] amdX: AdGuard responding on port 53
- [ ] amdX: Cloudflared tunnel active
- [ ] armX: Can reach amdX DNS and SSH into amdX
- [ ] Inventory JSON exports are up to date

---

**Last updated:** 2025-02-13
