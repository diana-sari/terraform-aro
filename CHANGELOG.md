# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Managed identity RBAC choice: `mi_use_builtin_operator_roles` (default `true`) keeps `reference/aro-azapi/modules/aro_role_assignments`; set to `false` to use `modules/aro-mi-rbac-legacy-network` (Network Contributor or optional scoped roles via `mi_minimal_network_role`, plus cluster MSI Managed Identity Operator wiring, aligned with the legacy `aro-managed-identity-permissions` model). State migration: `moved` from `module.aro_mi_rbac` to `module.aro_mi_rbac[0]` when staying on the built-in path.
- Community and tooling scaffolding: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md`, `.editorconfig`, optional `Dockerfile` / `.dockerignore`, expanded `.gitignore`, and README links for license and contributing.
- GitHub Actions workflow path `.github/workflows/ci.yml` (same behavior as the former `pr.yml`).
- Managed identity ARO cluster path uses **AzAPI** (`modules/aro-cluster-azapi`) and the **reference/aro-azapi** stack: `managed_identity` + `aro_role_assignments` (built-in ARO operator / Network Contributor RBAC), matching the known-good reference implementation.
- Providers: `Azure/azapi` (~> 2.4), root `azuread` (~> 2.53, aligned with `modules/aro-permissions`).
- `outbound_type` variable is passed through to the AzAPI cluster module (parity with the service-principal `azurerm_redhat_openshift_cluster` path).

### Changed
- **`reference/` gitignored:** Upstream MI module trees (`reference/aro-azapi`, optional `reference/terraform-azurerm-avm-res-redhatopenshift-openshiftcluster`) are no longer committed. Populate locally with `REFERENCE_ARO_AZAPI_URL=<git-url> make reference-sync` before `terraform init`. CI loads the same URL from GitHub Actions variable **`REFERENCE_ARO_AZAPI_URL`** (optional **`REFERENCE_ARO_AZAPI_REF`**). Maintainers must publish or point that variable at a repo containing the prior vendored layout (`modules/managed_identity`, `modules/aro_role_assignments`, …).
- **Licensing:** Root license file is `LICENSE` (Apache License 2.0 text); `LICENSE.txt` removed so links match common GitHub conventions (`README.md`, `CONTRIBUTING.md`).
- **Jumphost SSH (private clusters):** `jumphost_ssh_public_key_path` and `jumphost_ssh_private_key_path` now default to `null`; when both stay unset, Terraform generates an ED25519 keypair (`tls_private_key`), uses it for `remote-exec`, and publishes `jumphost_ssh_private_key_openssh` / `jumphost_ssh_public_key_openssh` outputs—avoiding passphrase-protected `~/.ssh/id_rsa`. To keep the prior behavior (host keys under `~/.ssh`), set both path variables explicitly. Paths use `pathexpand`; bring-your-own private keys must be unencrypted—passphrase-protected keys remain unsupported by provisioners.
- **Networking:** Optional Azure Firewall and UDR egress resources moved from root `11-egress.tf` into `modules/aro-network/egress.tf`, toggled from the root via `egress_traffic_restricted` / `firewall_subnet_cidr_block` module arguments (mapped from `restrict_egress_traffic` and `aro_firewall_subnet_cidr_block`). Root `10-network.tf` includes `moved` blocks to migrate existing state without replace.
- **Documentation:** `AGENTS.md` again includes a Terraform ARO **project supplement** after the Keel rule table (Keel covers generic Terraform/Git/agent rules; the supplement holds Azure/ARO/repo-only guidance). `.cursorrules` trimmed to point at DESIGN, Keel, and that supplement instead of duplicating them. README notes default Terraform-managed jumphost SSH keys/sensitive outputs and MI RBAC toggles (`mi_use_builtin_operator_roles`, `mi_minimal_network_role`). DESIGN and PLAN headers refreshed; DESIGN File Organization lists `02-locals.tf`, `03-data.tf`, `90-outputs.tf`, `modules/aro-network`, and corrects Naming vs Tagging subsection numbering.
- **Breaking (managed identity):** Replaced `module.aro_managed_identity_permissions` and `azurerm_resource_group_template_deployment.cluster_managed_identity` with reference modules plus `module.aro_cluster_azapi`. Existing state must drop the old resources and apply the new stack (see migration note below).
- `azurerm_redhat_openshift_cluster` remains for service principal mode only (`enable_managed_identities = false`).
- Outputs for MI clusters read from `module.aro_cluster_azapi` (console/API URLs and optional API/ingress IPs from AzAPI exports).
- `make destroy` / `scripts/destroy-managed-identity.sh` target the AzAPI cluster resource; legacy ARM template destroy is still detected if present in state.

### Removed
- Managed identity cluster provisioning via ARM template parameters in root `50-cluster.tf` (template file may still exist on disk but is no longer referenced).

### Migration
- If state contains `azurerm_resource_group_template_deployment.cluster_managed_identity`, run `terraform state rm` on that address (after deleting the cluster if needed), then `terraform apply` to create the new modules. Green-field applies need no action.

### Fixed
- `reference/aro-azapi/modules/managed_identity`: `cluster_msi_role_assignments` used a hand-built `role_definition_id` string that did not stabilize against Azure/normalized refreshes (`role_definition_id` → known-after-apply, forcing perpetual replacement). Align with sibling RBAC wiring: **`role_definition_name = "Azure Red Hat OpenShift Federated Credential"`**, explicit **`principal_type = "ServicePrincipal"`**, **`skip_service_principal_aad_check = true`**. Added a **`random_uuid` keeper bump** (`role_assignment_authoring`) so migration uses new assignment GUIDs—a **replacement** ARM allows—instead of reusing old GUIDs and hitting **"doesn't support update"**. Expect assignment **replacement** once when upgrading stacks created with the older author style.
- `make pr` / `make test`: run Checkov on this repo’s Terraform while skipping the vendored AVM reference tree (`reference/terraform-azurerm-avm-res-redhatopenshift-openshiftcluster`), which is upstream example code and not this project’s contract surface.
- Remove unused managed-identity local maps in `02-locals.tf` so `tflint` (unused declarations) passes in `make pr` / CI.
- Plan-time validation: `outbound_type = "UserDefinedRouting"` now requires `restrict_egress_traffic = true` so route table and RBAC stay consistent with this stack.
- `scripts/destroy-managed-identity.sh`: detect AzAPI cluster in state without BSD `grep -c` zero-match exit issues.
- Documentation: AzAPI `ignore_changes` behavior for MI clusters; deprecation banner on `modules/aro-managed-identity-permissions` README.

## [1.0.0] - 2024-12-01

### Added
- `make test` target - Full test suite including terraform validate, fmt, tflint, checkov, and terraform plan
- `make pr` target - Pre-commit checks (validate, fmt, tflint, checkov) without terraform plan
- `make login` target - Automated login to ARO cluster using terraform outputs and Azure CLI credentials
- GitHub Actions workflow (`.github/workflows/pr.yml`) - Automated PR checks with PR comments
  - Runs `make pr` on pull requests and pushes to main
  - Posts PR comments with check results
  - Includes Terraform, tflint, and checkov setup
  - Caches Terraform providers for faster runs
- Terraform outputs: `cluster_name` and `resource_group_name` for easier cluster management
- Vendored `terraform-aro-permissions` module (v0.2.1) into `./modules/aro-permissions/`
  - Removes external git dependency
  - Faster terraform init
  - Self-contained repository
  - Original source documented in module source comment
- Checkov inline suppressions with justifications:
  - CKV_AZURE_119: Jumphost requires public IP for private cluster access
  - CKV2_AZURE_31: Subnets use NSG via associations or private endpoints
- Terraform `required_version` constraint: `>= 1.12`
- Provider version constraints: Added `random` (~>3.0) and `time` (~>0.9) to required_providers

### Changed
- **BREAKING:** Reorganized Terraform files with numeric prefixes per MOBB RULES
  - `terraform.tf` → `00-terraform.tf`
  - `variables.tf` → `01-variables.tf`
  - New: `02-locals.tf` - Consolidated all local values
  - `network.tf` → `10-network.tf`
  - `egress.tf` → `11-egress.tf`
  - `iam.tf` → `20-iam.tf`
  - `jumphost.tf` → `30-jumphost.tf`
  - `acr.tf` → `40-acr.tf`
  - `cluster.tf` → `50-cluster.tf`
  - New: `90-outputs.tf` - Consolidated all outputs
  - Note: Terraform automatically reads all `.tf` files, so functionality unchanged
- **BREAKING:** Standardized resource naming - converted hyphens to underscores
  - `azurerm_subnet.jumphost-subnet` → `azurerm_subnet.jumphost_subnet`
  - `azurerm_public_ip.jumphost-pip` → `azurerm_public_ip.jumphost_pip`
  - `azurerm_network_interface.jumphost-nic` → `azurerm_network_interface.jumphost_nic`
  - `azurerm_network_security_group.jumphost-nsg` → `azurerm_network_security_group.jumphost_nsg`
  - `azurerm_linux_virtual_machine.jumphost-vm` → `azurerm_linux_virtual_machine.jumphost_vm`
  - `azurerm_network_interface_security_group_association.association` → `azurerm_network_interface_security_group_association.jumphost_association`
- Enhanced all variable descriptions with more detail, usage examples, and constraints
- Enhanced TODO comments with context, rationale, and references to DESIGN.md
- **BREAKING:** `aro_version` variable now defaults to `null` instead of `"4.16.30"`
  - If `aro_version` is not provided, the latest available version for the region is automatically detected
  - To specify a version explicitly, set `aro_version = "4.16.30"` (or desired version)
  - Detection uses: `az aro get-versions -l <location>` and selects the latest version

### Added
- Gap analysis comparing existing codebase to MOBB RULES standards
- `02-locals.tf` - Consolidated all local values from multiple files
- `03-data.tf` - Data sources including automatic ARO version detection
- `90-outputs.tf` - Consolidated all outputs from multiple files
- Descriptions added to all 5 outputs (`console_url`, `api_url`, `api_server_ip`, `ingress_ip`, `public_ip`)
- Enhanced variable descriptions with detailed explanations, usage examples, and constraints
- Enhanced TODO comments with context, rationale, and references to DESIGN.md
- Automatic ARO version detection - `aro_version` variable now defaults to `null` and automatically detects latest available version if not provided
- `external` provider added for shell command execution
- DESIGN.md - Project design document documenting architecture, constraints, and design decisions
  - Documents project intent, high-level architecture, design decisions, constraints, and non-goals
  - Includes context-aware security approach documentation
  - References external documentation and future considerations
- PLAN.md - Implementation plan tracking tasks and progress
  - Updated to reflect MOBB RULES adoption progress
- CHANGELOG.md - This file, tracking all notable changes
- AGENTS.md - Project-specific best practices compiled from MOBB RULES
  - Compiles Terraform, Azure, and ARO best practices
  - Documents existing patterns and deviations
  - Includes context-aware application guidelines
  - Documents security approach for example/demo context
- .cursorrules - AI agent instructions referencing AGENTS.md
  - Provides guidelines for AI coding agents working on this project
  - References DESIGN.md, AGENTS.md, and PLAN.md
- Makefile targets: `validate`, `fmt`, `fmt-fix`, `check`, `lint` - Standard MOBB RULES targets for Terraform validation and formatting
  - `validate` - Run terraform validate
  - `fmt` - Check formatting (non-destructive)
  - `fmt-fix` - Fix formatting automatically
  - `check` - Run both validate and fmt checks
  - `lint` - Run linting checks (currently wraps check)
- `make test` - Full test suite with terraform plan (requires Azure CLI login)
- `make pr` - Pre-commit checks without terraform plan (no Azure credentials needed)
- `make login` - Automated ARO cluster login using terraform outputs
- `ManagedBy = "Terraform"` tag to default tags variable

### Changed
- Makefile - Added standard MOBB RULES targets for validation and formatting
- **BREAKING:** Standardized Terraform resource identifiers to use underscores consistently
  - `azurerm_subnet.jumphost-subnet` → `azurerm_subnet.jumphost_subnet`
  - `azurerm_public_ip.jumphost-pip` → `azurerm_public_ip.jumphost_pip`
  - `azurerm_network_interface.jumphost-nic` → `azurerm_network_interface.jumphost_nic`
  - `azurerm_network_security_group.jumphost-nsg` → `azurerm_network_security_group.jumphost_nsg`
  - `azurerm_linux_virtual_machine.jumphost-vm` → `azurerm_linux_virtual_machine.jumphost_vm`
  - `azurerm_network_interface_security_group_association.association` → `azurerm_network_interface_security_group_association.jumphost_association`
- All outputs - Added descriptions per MOBB RULES best practices
- All variables - Improved descriptions for clarity and consistency
- Variables - Added `nullable` attribute to optional variables (`resource_group_name`, `pull_secret_path`, `domain`)
- Variables - Standardized description format (capitalized CIDR, clearer explanations)
- Variables - Fixed typo in `aro_private_endpoint_cidr_block` description
- Variables - Improved validation error messages (fixed "Must be not be empty" → "Must not be empty")

## [0.1.0] - 2024-12-01

### Added
- Initial Terraform codebase for ARO cluster deployment
- Support for public ARO clusters
- Support for private ARO clusters
- Conditional Azure Firewall for egress traffic restriction
- Conditional jumphost VM for private cluster access
- Conditional Azure Container Registry (ACR) with private endpoint
- Service principal management via `terraform-aro-permissions` module
- Basic Makefile with targets: `help`, `tfvars`, `init`, `create`, `create-private`, `create-private-noegress`, `destroy`, `destroy-force`, `delete`, `clean`
- README.md with usage instructions
- variables.tf with comprehensive variable definitions
- terraform.tfvars.example for variable reference

### Notes
- This changelog entry documents the initial state of the project before MOBB RULES adoption
- Project supports both public and private ARO cluster deployments
- Security defaults are permissive for example/demo use cases
- Production deployments require security hardening (documented in DESIGN.md)

[Unreleased]: https://github.com/rh-mobb/terraform-aro/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rh-mobb/terraform-aro/releases/tag/v1.0.0
[0.1.0]: https://github.com/rh-mobb/terraform-aro/releases/tag/v0.1.0
