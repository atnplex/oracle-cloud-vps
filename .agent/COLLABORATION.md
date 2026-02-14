# Agent Collaboration Protocol

## Agents

| ID | Role | Scope |
|---|---|---|
| Comet-OCI-1 | Inventory collector | Account 1 — READ ONLY |
| Comet-OCI-2 | Inventory collector | Account 2 — READ ONLY |
| Comet-OCI-3 | Inventory + deploy | Account 3 — inventory first, deploy after approval |
| AG-Architect | Orchestrator | Repo structure, BASELINE, reviews |

## Commit Message Convention

```
<type>(<scope>): <description>

Types: inventory, docs, fix, feat, chore
Scopes: account1, account2, account3, repo, baseline
```

Examples:
- `inventory(account3): compute instances and VNICs`
- `docs(baseline): update CIDR table with account 2 values`

## Task Status

### Account 1
- [ ] Compartment inventory
- [ ] Compute instances
- [ ] Network (VCN, subnets, routes, NSGs, security lists)
- [ ] Storage (boot volumes, block volumes)
- [ ] IAM (policies, groups)
- [ ] Custom images
- [ ] Summary markdown
- [ ] Baseline deviation report

### Account 2
- [ ] Compartment inventory
- [ ] Compute instances
- [ ] Network (VCN, subnets, routes, NSGs, security lists)
- [ ] Storage (boot volumes, block volumes)
- [ ] IAM (policies, groups)
- [ ] Custom images
- [ ] Summary markdown
- [ ] Baseline deviation report

### Account 3
- [ ] Compartment inventory
- [ ] Compute instances
- [ ] Network (VCN, subnets, routes, NSGs, security lists)
- [ ] Storage (boot volumes, block volumes)
- [ ] IAM (policies, groups)
- [ ] Custom images
- [ ] Summary markdown
- [ ] Baseline deviation report
- [ ] Deploy checklist created
- [ ] Deploy approved
- [ ] Deploy executed

## File Ownership

- `/inventory/account1/` — Comet-OCI-1 only
- `/inventory/account2/` — Comet-OCI-2 only
- `/inventory/account3/` — Comet-OCI-3 only
- `BASELINE.md`, `README.md` — AG-Architect (this file's author)
- `.agent/` — any agent can write, but only to their own sections/files

## Conflict Rules

- Agents must NOT edit files outside their scope
- If two agents need to update the same file, use separate sections clearly marked
- Questions go in `.agent/NOTES.md` with `[DECISION REQUIRED]` tags
"