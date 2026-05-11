# AGENTS.md

<!-- keel:start - DO NOT EDIT between these markers -->
## Rules

| Rule | Globs | Always Apply |
|------|-------|--------------|
| agent-behavior | `["**/*"]` | true |
| base | `["**/*"]` | true |
| markdown | `["**/*.md"]` | false |
| scaffolding | `["**/*"]` | true |
| terraform | `["**/*.tf", "**/*.tfvars", "**/*.tfvars.json"]` | false |

## Rule Details

### agent-behavior
- **Description:** Universal behavioral safety rules for AI agents interacting with live systems
- **Globs:** `["**/*"]`
- **File:** `.agents/rules/keel/agent-behavior.md`

### base
- **Description:** Global coding standards that apply to all files and languages
- **Globs:** `["**/*"]`
- **File:** `.agents/rules/keel/base.md`

### markdown
- **Description:** Markdown writing conventions for .md files
- **Globs:** `["**/*.md"]`
- **File:** `.agents/rules/keel/markdown.md`

### scaffolding
- **Description:** Interactive guidance for essential project scaffolding files
- **Globs:** `["**/*"]`
- **File:** `.agents/rules/keel/scaffolding.md`

### terraform
- **Description:** Best practices and rules for Terraform infrastructure as code
- **Globs:** `["**/*.tf", "**/*.tfvars", "**/*.tfvars.json"]`
- **File:** `.agents/rules/keel/terraform.md`
<!-- keel:end -->

## Terraform ARO — project supplement

**Keel** (table above) supplies generic agent behavior, Git hygiene, Terraform style, markdown, and scaffolding. In **Cursor**, those live under [`.cursor/rules/keel/`](.cursor/rules/keel/); the same text is mirrored under [`.agents/rules/keel/`](.agents/rules/keel/) for other tools. **Everything below** is specific to this Azure ARO Terraform repo and [MOBB](https://github.com/rh-mobb)-style practice—avoid repeating Keel’s generic bullets here.

### Rule precedence

1. **[DESIGN.md](DESIGN.md)** — intent, boundaries, security trade-offs (highest).
2. **This supplement** — layout, identity modes, modules, toggles, Azure/ARO conventions for *this* tree.
3. **Keel rules** — cross-language and default Terraform guidance.

### Project context

- **Cloud:** Azure · **Platform:** ARO (Azure Red Hat OpenShift) · **IaC:** Terraform.
- **Purpose:** Example / demo / learning; permissive defaults are intentional—document hardening for anything stricter.
- **Tasks / roadmap:** [PLAN.md](PLAN.md).

### Philosophy (MOBB)

- **Simplicity over complexity** — straightforward modules and files over deep abstraction.
- **WET over DRY** — some duplication is acceptable for clarity in an example repo.
- **Context-aware controls** — strictness follows environment (sandbox vs production).

### Uncertain or exploratory requests

When the user sounds unsure—hedging (“maybe”, “I would think”, “probably”), tentative phrasing, or a message framed as an open question—treat that as a signal to **clarify before building**, not as a green light to implement the first interpretation.

- **Restate and refine** — summarize what you understood, ask targeted questions, and narrow scope until the goal is explicit enough to act on.
- **Raise certainty** — prefer a short alignment step (options, trade-offs, what “done” looks like) over rushing to code or Terraform edits.
- **Gentle pushback is allowed** — if a different approach is safer, simpler, or better aligned with DESIGN.md or this supplement, say so briefly and offer the alternative.

Do not skip this step just to appear fast; wrong certainty costs more than a brief clarification.

### Root module layout

Numbered root files (order-friendly):

| Prefix | Focus |
|--------|--------|
| `00-terraform.tf` | Providers / Terraform block |
| `01-variables.tf` | Variables |
| `02-locals.tf` | Locals |
| `03-data.tf` | Data sources |
| `10-network.tf` | `module.aro_network`: VNet, subnets, NSGs; optional firewall + UDR in `modules/aro-network/egress.tf` when `restrict_egress_traffic` is true |
| `20-iam.tf` | Identities and RBAC |
| `30-jumphost.tf` | Optional jumphost |
| `40-acr.tf` | ACR |
| `50-cluster.tf` | ARO cluster (path depends on identity mode) |
| `90-outputs.tf` | Outputs |

Submodules live under `modules/` and `reference/`; see DESIGN.md for boundaries.

### Naming and tags

- Resources: **`${local.name_prefix}-<resource-type>-<identifier>`** (Azure-style lowercase hyphenated names).
- Tags: keep **`environment`**, **`owner`**, **`ManagedBy`** consistent; defaults are permissive—see variables and DESIGN.md.

### Identity modes (do not confuse paths)

- **Service principal (default):** `azurerm_redhat_openshift_cluster` plus vendored [**`modules/aro-permissions`**](modules/aro-permissions/) (terraform-aro-permissions v0.2.1). Root `20-iam.tf` uses built-in **Network Contributor** and **Contributor** (Microsoft tutorial posture); optional custom minimal roles are still supported by the module if you pass `minimal_network_role` / `minimal_aro_role` there.
- **Managed identities (preview):** **`reference/aro-azapi`** modules (directory is **gitignored**—populate with `make reference-sync` using `REFERENCE_ARO_AZAPI_URL`; CI uses the GitHub Actions variable of the same name) plus [**`modules/aro-cluster-azapi`**](modules/aro-cluster-azapi/) (AzAPI). RBAC defaults to built-in ARO operator roles (`mi_use_builtin_operator_roles`, default true); optional legacy-style network RBAC lives in [**`modules/aro-mi-rbac-legacy-network`**](modules/aro-mi-rbac-legacy-network/). Prefer this stack for new MI work; [**`modules/aro-managed-identity-permissions`**](modules/aro-managed-identity-permissions/) is legacy—see its README if you touch old state.

### Azure networking and ARO

- Dedicated control plane / worker subnets, service endpoints (e.g. Storage, ACR), private endpoint policies off on ARO subnets where required.
- **Outbound:** `LoadBalancer` vs `UserDefinedRouting` must stay consistent with `restrict_egress_traffic` and DESIGN.md (firewall + route tables when restricted).
- **Private API/ingress:** optional jumphost path; document connectivity when changing NSGs or SSH sources.

### Security posture (example repo)

- NSGs and firewall rules may be broad for learning; call out production tightening in PRs when you touch them.
- Toggles: `restrict_egress_traffic`, `apply_restricted_policies` (see variables + DESIGN.md).

### Makefile and CI

- **`reference/`** — `terraform init` requires `./reference/aro-azapi` (managed identity module sources). Clone via **`make reference-sync`** (`REFERENCE_ARO_AZAPI_URL`); GitHub Actions sets repository/org variable **`REFERENCE_ARO_AZAPI_URL`** before `make pr`.
- **`make pr`** — `terraform validate`, `fmt -check`, optional **tflint** / **checkov** (matches automation).
- **`make test`** — broader local checks, optional **`terraform plan`** when Azure CLI is logged in.
- **GitHub Actions:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml) on push and PR to `main` (runs `make pr`).

For variable/output descriptions, formatting, pinning, and validation habits, follow the **Keel Terraform** rule—this file does not duplicate that list.

### Versioning and changelog

- **SemVer**; **CHANGELOG.md** [Keep a Changelog](https://keepachangelog.com/); release steps are summarized in README / PLAN as needed.

### Doc map

| File | Role |
|------|------|
| [DESIGN.md](DESIGN.md) | Architecture and constraints |
| [PLAN.md](PLAN.md) | Tasks |
| [README.md](README.md) | Usage |
| [CHANGELOG.md](CHANGELOG.md) | Release notes |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributor flow |
