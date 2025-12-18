# CI/CD Strategy

The GitHub Actions workflow in `.github/workflows/ci.yml` enforces quality gates for every push and pull request without requiring AWS credentials.

## Pipeline Overview

| Job | Purpose | Key Steps |
| --- | --- | --- |
| Terraform Validation | Guarantees Infrastructure as Code formatting and correctness | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` |
| Lambda Validation & Packaging | Ensures the Node.js 22 Lambda compiles and can be packaged before Terraform consumes it | `npm install`, `npm run build`, `npm run package` |
| Terraform Security Scans | Detects common misconfigurations using Checkov | `checkov -d infra` |
| Markdown Lint | Keeps documentation readable | `markdownlint-cli2` on all Markdown files |

## Design Considerations

* **Provider-agnostic validation** – `terraform init` runs with `-backend=false` so the workflow never attempts to access remote state or AWS credentials.
* **Deterministic Lambda packaging** – The Lambda job builds directly from `functions/items`, matching how the Terraform `archive_file` module sources code. Packaging failures surface early instead of during deployment.
* **Defense in depth** – Checkov enforces IaC security baselines (encryption, IAM, logging) without requiring AWS credentials.
* **Documentation as code** – Markdown linting keeps READMEs and design docs review-ready and encourages ongoing documentation updates alongside code changes.

## Local Reproduction

Developers can mimic the CI steps with:

```bash
# Terraform validation
(cd infra/envs/dev && terraform fmt -recursive && terraform init -backend=false && terraform validate)

# Lambda validation / packaging
(cd functions/items && npm install && npm run build && npm run package)

# Security scans
(cd infra && checkov -d .)

# Docs lint
npx markdownlint-cli2 "**/*.md"
```
