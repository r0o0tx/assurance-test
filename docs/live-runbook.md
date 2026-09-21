# Live deployment runbook

How to stand the platform up on Azure, verify every requirement, and tear it down.
The delivered posture is private-link origins: the web and api tiers run on VM Scale
Sets behind internal-only Standard load balancers, and Azure Front Door (Premium,
managed OWASP plus bot WAF) reaches each tier privately through a Private Link Service,
so no origin has a public IP. A NAT gateway supplies outbound egress for the internal
subnets (needed at boot for image pull and package install). PostgreSQL Flexible Server
is private, zone-redundant, TLS-only.

Commands below are run from the repository root.

## 0. Two ways to deploy

The locked prod stack should be deployed and destroyed through CI, not local Terraform.
The state, Key Vault, and backup storage data planes default-deny public network access
and allow only the app subnets and a single operator or runner IP. Those data-plane
firewalls are IPv4 only. A GitHub runner has a stable IPv4 that the firewalls accept, so
CI is the reliable path; a workstation that egresses over IPv6 is rejected by them.

- Prod (VMSS, private-link origins): drive through the pipeline (sections 3 to 6).
- Local Terraform is only appropriate for the AKS and ACA variants, which use local
  state and are not network-restricted (section 8).

## 1. Prerequisites (operator runs these once)

```bash
az login                 # choose the target subscription
az account show          # confirm the right subscription is active
```

The Azure CLI token in `~/.azure` is shared, so subsequent `az` and `terraform` calls
reuse the same session.

## 2. One-time bootstrap (single resource group, state storage, OIDC)

```bash
# State resource group + storage account (kept outside Terraform's managed set)
LOCATION=eastus bash scripts/bootstrap/create-state.sh
# record STATE_STORAGE_ACCOUNT (call it STATE_SA) and STATE_RG

# OIDC federation for the pipeline
bash scripts/bootstrap/setup-oidc.sh
# record AZURE_CLIENT_ID / AZURE_TENANT_ID / AZURE_SUBSCRIPTION_ID
```

Set these as GitHub repository variables on the CI repository: `AZURE_CLIENT_ID`,
`AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `STATE_RG`, `STATE_SA`,
`TF_VAR_SSH_PUBLIC_KEY`. Add the delivery mirror URL as the `MIRROR_REMOTE` secret.

Pre-flight quota check:

```bash
az vm list-usage --location eastus -o table | grep -Ei "Total Regional vCPUs|DSv5|Dsv4"
```

## 3. SSH key for VMSS admin

Azure rejects ed25519 for Linux VMSS admin keys, so the key must be RSA.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/astst -N "" -C "astst-vmss"
gh variable set TF_VAR_SSH_PUBLIC_KEY -b "$(cat ~/.ssh/astst.pub)"
```

The public key is non-sensitive and is passed to CI as a repository variable; the private
key stays local and is never committed.

## 4. Deploy through the pipeline (self-bootstrapping)

A push to `main` runs `ci` (unit tests and image build validation), then `deploy` (see
`.github/workflows/deploy.yml`, which fans out to the reusable
`.github/workflows/deploy-env.yml`). The deploy job self-bootstraps an environment from
nothing:

1. Opens this runner's egress IP on the state, Key Vault, and backup storage firewalls
   (they default-deny public access), retrying `terraform init` while the state rule
   propagates.
2. Applies `-target=module.registry` first so the container registry exists.
3. Builds and pushes the `web`, `api`, and `backup` images to that registry (so the
   nodes and the backup container group have something to pull on first boot).
4. Runs the full `terraform apply` (retried to absorb Front Door metric-definition
   eventual consistency).
5. Approves the pending Front Door private-endpoint connections on `astst-web-pls` and
   `astst-api-pls`.
6. Waits for VMSS instance health, then starts a health-gated rolling upgrade (a no-op
   on a fresh scale set already on the latest model).
7. Smoke-tests through the Front Door hostname (`scripts/smoke/smoke-test.sh`).
8. Removes the runner IP from every firewall on cleanup.

To trigger it, push to `main` (or re-run the last `ci` run). Prod is a protected GitHub
environment, so the `prod` job can require a manual approval before it proceeds.

Timing note: DB, VMSS, Front Door, and the private-link approvals take roughly 15 to 25
minutes end to end. Private-link origins can take several minutes after approval before
the edge serves traffic; the smoke test retries to absorb this.

## 5. Access the running environment

```bash
# operator helper scripts under scripts/access/ wrap SSH-less VM exec, log tails, and db-connect
bash scripts/access/fd-url.sh
bash scripts/access/status.sh
```

## 6. Verify every requirement

Run these with the resource group and Front Door hostname for the environment. `RG` is
`rg-assurance-test-prod` for prod.

```bash
FD="<frontdoor_hostname>"
RG=rg-assurance-test-prod

# R1 web+api reachable, R10 CDN edge
bash scripts/smoke/smoke-test.sh "$FD"
curl -fsSI "https://$FD/stylesheets/style.css" | grep -i "x-cache\|x-azure-ref"

# Private-link posture: the Front Door private-endpoint connections are Approved
for pls in astst-web-pls astst-api-pls; do
  az network private-endpoint-connection list --name "$pls" -g "$RG" \
    --type Microsoft.Network/privateLinkServices \
    --query "[].properties.privateLinkServiceConnectionState.status" -o tsv
done   # expect: Approved

# Origins have no public IP: the only public IP in the RG is the NAT gateway egress IP
az network public-ip list -g "$RG" --query "[].{name:name, ip:ipAddress}" -o table
# expect a single entry, astst-nat-pip

# WAF blocks an injection probe (expect 403 from Prevention mode)
curl -s -o /dev/null -w "%{http_code}\n" "https://$FD/?q=1'%20OR%20'1'='1"

# R2 db private (expect Disabled)
az postgres flexible-server show -g "$RG" -n "$(terraform output -raw db_server_name)" \
  --query "network.publicNetworkAccess"

# R4 instance failure: delete an api node, traffic stays up, node returns
ID=$(az vmss list-instances -g "$RG" -n astst-api-vmss --query "[0].instanceId" -o tsv)
az vmss delete-instances -g "$RG" -n astst-api-vmss --instance-ids "$ID"
bash scripts/runtime/status.sh

# R4 db HA failover
az postgres flexible-server restart -g "$RG" -n "$(terraform output -raw db_server_name)" --failover Forced

# R7 backups: force the in-VNet job and list the dump
az container start -g "$RG" -n astst-backup 2>/dev/null || true
az storage blob list --account-name "$(terraform output -raw backup_sa)" \
  --container-name backups --auth-mode login -o table | grep appdb

# R8 logs off-host
for i in $(seq 1 20); do curl -s "https://$FD/" >/dev/null; done
az monitor log-analytics query -w "$(terraform output -raw law_id)" \
  --analytics-query "Syslog | where TimeGenerated > ago(15m) | take 5" -o table

# R5 zero-downtime: run a client loop in one shell, push a new commit in another
#   for i in $(seq 1 300); do curl -fsS "https://$FD/health" >/dev/null || echo FAIL; sleep 1; done
```

## 7. Backup and restore drill

The daily backup runs automatically, but the job and its restore counterpart can be run
on demand from inside the in-VNet backup container (it already holds the managed identity,
the Key Vault path, and the private DB route).

The restore is deliberately non-destructive: with no target argument it restores into a
separate verification database (`<appdb>_restore_verify`), so the dump is validated in
isolation and the live application database is never overwritten. This is the standard
recovery drill: restore to a scratch database, check the data loaded, then drop it.

```bash
RG=rg-assurance-test-prod

# 1. Take a backup now and confirm the blob lands
az container exec -g "$RG" -n astst-backup --exec-command "/usr/local/bin/pg_backup.sh"
az storage blob list --account-name "$(terraform output -raw backup_sa)" \
  --container-name backups --auth-mode login -o table | grep appdb

# 2. Restore the named dump into an isolated verification database
az container exec -g "$RG" -n astst-backup \
  --exec-command "/usr/local/bin/pg_restore.sh appdb/<timestamp>.sql.gz"

# 3. Confirm the data loaded into the verification database, then drop it
az container exec -g "$RG" -n astst-backup --exec-command \
  "bash -lc 'PGPASSWORD=\$(az keyvault secret show --vault-name \$KV_NAME --name DBPASS --query value -o tsv) PGSSLMODE=require psql -h \$(az keyvault secret show --vault-name \$KV_NAME --name DBHOST --query value -o tsv) -U \$(az keyvault secret show --vault-name \$KV_NAME --name DBUSER --query value -o tsv) -d appdb_restore_verify -c \"\\dt\"'"
```

The backup logs `uploaded appdb/...` and the restore logs `restored appdb/... into
appdb_restore_verify`; both are shipped to Log Analytics through the container group's
diagnostics, and the backup-freshness alert fires if no `uploaded` line appears in a
48-hour window.

## 8. Teardown

Destroy through CI, for the same IPv4 firewall reason as deploy. A GitHub runner's
stable IPv4 is accepted by the locked data planes.

```bash
gh workflow run destroy.yml -f environment=prod -f confirm=prod
```

Key Vaults are left soft-deleted on destroy by design: the deploy identity is
least-privileged and is not granted the vault purge action. Soft-deleted vaults incur no
cost and expire on their retention window.

After the run, verify the resource group has returned to its small baseline (only the
state resource group contents and any intentionally kept resources remain, no billable
workload resources):

```bash
az resource list -g rg-assurance-test-prod -o table
az network public-ip list -g rg-assurance-test-prod -o table   # expect none
```

## 9. AKS and ACA variants (local Terraform is fine)

The AKS and ACA stacks use local state and are not behind the IPv4 data-plane firewalls,
so they run from a workstation directly:

```bash
cd deploy-aks   # or deploy-aca
terraform init
terraform apply
# tear down with terraform destroy when done
```
