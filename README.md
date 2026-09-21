# assurance-test platform

Continuous delivery for a scalable, secure three-tier Node.js application on Azure,
provisioned end-to-end with Terraform and deployed by an automated pipeline.

```
Internet -> Azure Front Door (CDN, WAF, geo) --Private Link--> web tier (VMSS) -> api tier (VMSS) -> PostgreSQL (private)
```

![architecture](diagram/architecture.png)

## Architecture

| Concern | Implementation |
|---------|----------------|
| Web + API tiers, Internet-facing | Azure Front Door routes `/*` to the web tier and `/api/*` to the api tier. Each tier runs on a VM Scale Set behind an internal Standard Load Balancer across three availability zones |
| Origins never public | Front Door reaches each tier over a Private Link Service; the load balancers are internal-only and the instances have no public IP. The single public IP in the resource group is a NAT gateway used only for outbound |
| Database, private | Azure Database for PostgreSQL Flexible Server, zone-redundant HA, no public endpoint, reachable only from the api and backup subnets |
| East-west (web -> api) | The api tier has an internal load balancer; the web tier calls it privately inside the VNet |
| Outbound egress | A NAT gateway gives the internal-only workload subnets controlled egress from a single known IP (image pull, package install) |
| Infrastructure as code | Terraform (`azurerm`), remote state in Azure Storage with native blob-lease locking, one resource group per environment |
| Instance-failure resilience | VMSS health probes + Application Health Extension + automatic instance repair across zones; zone-redundant DB failover |
| Zero-downtime deploys | Health-gated VMSS rolling upgrades; immutable, SHA-tagged container images in ACR |
| Automated deployment | GitHub Actions with OIDC: test -> build+push images -> `terraform apply` -> approve private endpoints -> rolling upgrade -> smoke test |
| Daily backups | Flexible Server point-in-time restore (7 days) + an in-VNet `pg_dump` job to versioned blob storage |
| Centralized logs | Azure Monitor Agent ships container/syslog off-host to a Log Analytics workspace; all managed services send diagnostics there too |
| Historical metrics + alerts | Azure Monitor dashboard + metric alerts (web/api/db CPU, Front Door latency and 5xx, DB storage), a synthetic availability test, and a backup-freshness alert, wired to an email action group |
| CDN by client location | Azure Front Door global edge with caching for static assets |
| Secrets | Azure Key Vault + VMSS managed identity; no credentials on disk or in the repo |

### Security posture

- **Edge**: Premium Front Door with the managed OWASP ruleset and bot-manager rules in blocking mode.
- **Private origins**: the tiers sit behind internal load balancers exposed to Front Door only through a Private Link Service, so no origin is reachable from the public internet.
- **Locked data planes**: Key Vault, the backup storage account and the Terraform state account default-deny public access and are reachable only from the app subnets (service endpoints) and the CI runner IP.
- **Transport**: the database connection is TLS-only; secrets come from Key Vault via managed identity.
- **Supply chain**: keyless OIDC deploys, workflow actions pinned to commit digests, and the image scan runs in a job with no cloud credentials.
- **Access**: optional Entra ID role groups mapped to least-privilege scoped roles; a Developer-SKU Bastion for private VM access.

## Requirement mapping

| Requirement | Where |
|-------------|-------|
| Web + API exposed to the Internet | `infra/modules/edge`, `infra/modules/compute` |
| DB not reachable from the Internet | `infra/modules/data` (private access), `infra/modules/network` (NSGs) |
| Fully provisioned via IaC | `infra/` |
| Handle instance failures | `infra/modules/compute` (VMSS, health, auto-repair), `infra/modules/data` (HA) |
| No-downtime updates | `infra/modules/compute` (rolling upgrade), `.github/workflows/deploy-env.yml` |
| Automated code deployment | `.github/workflows/` |
| Daily DB + storage backup | `infra/modules/data` (PITR), `infra/modules/backup`, `scripts/backup/` |
| Logs accessible off-host | `infra/modules/observability` (Log Analytics, DCR, diagnostics) |
| Historical metrics | `infra/modules/observability` (dashboard, alerts) |
| CDN by location | `infra/modules/edge` (Front Door) |
| Runtime start/stop/scale scripts | `scripts/runtime/` |

## Repository layout

```
app/                     forked application (web, api) + Dockerfiles + tests
infra/                   Terraform: root stack + modules (network, security, registry,
                         data, compute, edge, observability, backup, rbac, access)
infra/environments/      per-environment sizing and toggles (dev, staging, prod)
scripts/bootstrap/       one-time state + OIDC setup
scripts/runtime/         start / stop / scale / restart / status
scripts/backup/          pg_dump / pg_restore + job image
scripts/access/          read-only day-2 helpers (status, logs, exec) via az + RBAC
scripts/onboarding/      add / remove a user from an Entra role group
scripts/smoke/           post-deploy smoke test
.github/workflows/       ci, deploy, deploy-env, security, mirror, destroy
diagram/                 architecture diagram + slide deck
docs/                    live deployment + verification runbook
deploy-aks/              alternative: AKS + Helm
deploy-aca/              alternative: Azure Container Apps
```

## Deployment

The pipeline stands an environment up from nothing. On a push to `main`, `ci` runs
tests and an image scan; `deploy` then creates the registry, builds and pushes the
tier images, applies the full stack, approves the Front Door private endpoints, runs
a health-gated rolling upgrade, and smoke-tests through Front Door. Environments are
selected by the `environment` variable (`infra/environments/<env>.tfvars`).

To provision manually (for example a first bootstrap), see `docs/live-runbook.md`,
or in short:

```bash
# one-time: resource group + Terraform state storage
LOCATION=eastus bash scripts/bootstrap/create-state.sh

cd infra
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"   # RSA key (Azure requirement)
terraform init \
  -backend-config="resource_group_name=rg-assurance-test-prod" \
  -backend-config="storage_account_name=<state-account>"
# the registry must exist and hold images before the full apply; the pipeline
# does this in one run (see .github/workflows/deploy-env.yml)
terraform apply -var-file=environments/prod.tfvars \
  -var web_image_tag=<sha> -var api_image_tag=<sha>

# verify
bash scripts/smoke/smoke-test.sh "$(terraform output -raw frontdoor_hostname)"
```

Alternative deployment models are in `deploy-aks/` (Kubernetes + Helm) and
`deploy-aca/` (Azure Container Apps); the VMSS stack is the reference implementation.

## Runtime operations

```bash
scripts/runtime/status.sh                 # instances, health, model
scripts/runtime/scale.sh api 3            # scale a tier
scripts/runtime/restart.sh web            # rolling restart
```

## Teardown

```bash
# via the pipeline (stable runner IP the locked data planes accept)
gh workflow run destroy.yml -f environment=prod -f confirm=prod

# or locally
cd infra && terraform destroy -var-file=environments/prod.tfvars
```
