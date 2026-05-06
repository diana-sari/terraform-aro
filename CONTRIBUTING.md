# Contributing

Thank you for helping improve this Terraform ARO example. This document explains how we work and what to run before opening a pull request.

## Code of conduct

All participants must follow the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Reports go through the process described there.

## Where to discuss

- **Bugs and features:** [GitHub Issues](https://github.com/rh-mobb/terraform-aro/issues)
- **Security-sensitive reports:** see [SECURITY.md](SECURITY.md) (private advisory), not a public issue

## Before you open a PR

1. Read [DESIGN.md](DESIGN.md) for scope and intent, and [AGENTS.md](AGENTS.md) for project conventions.
2. **Managed-identities reference modules:** `reference/` is gitignored. Clone the upstream snapshot your organization documents (GitHub Actions uses repository variable `REFERENCE_ARO_AZAPI_URL`). Example:
   ```bash
   REFERENCE_ARO_AZAPI_URL=https://github.com/your-org/terraform-aro-reference-aro-azapi.git make reference-sync
   ```
   Optional: `REFERENCE_SYNC_AVM=0` skips the extra Azure AVM checkout used only for Checkov path skips.
3. Format Terraform: `make fmt-fix`
4. Run the same checks as CI: `make pr`  
   - Requires Terraform, optional `tflint` and `checkov` (versions aligned with [`.github/workflows/ci.yml`](.github/workflows/ci.yml)); `make pr` runs `terraform init`, which requires `reference/aro-azapi` to exist (see step 2).
5. For a deeper local run (includes optional `terraform plan` when `az` is logged in): `make test`

## PR checklist

- [ ] `make pr` passes
- [ ] User-visible behavior or variables documented in `README.md` / `DESIGN.md` / `CHANGELOG.md` as appropriate
- [ ] No secrets committed (use `terraform.tfvars` locally; it is gitignored)

## Optional: checks in Docker

If you prefer a container with Terraform, tflint, and checkov installed:

```bash
# On Apple Silicon, add: --platform linux/amd64 (image uses linux_amd64 release binaries)
docker build -t terraform-aro-ci .
docker run --rm -v "$PWD:/workspace" -w /workspace \
  -e REFERENCE_ARO_AZAPI_URL="$REFERENCE_ARO_AZAPI_URL" \
  terraform-aro-ci bash -lc 'make reference-sync && make pr'
```

The image runs as a non-root user and expects you to mount the repository at `/workspace`.

## License

By contributing, you agree that your contributions are licensed under the same terms as the project — see [LICENSE](LICENSE).
