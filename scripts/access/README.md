# Access scripts

Thin wrappers for reaching the running platform. They resolve resource names by
convention (prefix + environment) and query Azure directly, so you only need
`az login` and the RBAC your role grants — no Terraform state access.

Set the target environment with `ENV` (default `prod`):

```bash
ENV=staging ./status.sh
```

| Script | What it does | Access needed |
|--------|--------------|---------------|
| `status.sh` | One-shot health: Front Door, both scale sets, DB, latest backup | Reader (+ blob read for backup line) |
| `fd-url.sh` | Print the public Front Door URL | Reader |
| `logs.sh [tier] [--tail]` | Recent host/container Syslog from Log Analytics | Log Analytics Reader |
| `vm-exec.sh <tier> [id] [cmd]` | Run a command on a VMSS instance (management plane, no VPN needed) | VMSS run-command |
| `connect-vm.sh <tier> [id]` | Interactive SSH via Bastion (falls back to guidance) | Bastion + SSH key |
| `db-connect.sh [sql]` | psql into the private PostgreSQL | Network path to VNet + KV secret read |
| `backup-exec.sh [cmd]` | Run a command in the backup container (default: trigger a backup) | Container exec |
| `aks-shell.sh [cmd]` | `az aks get-credentials` + kubectl (AKS variant) | AKS user |
| `aca-logs.sh <tier>` | Stream Container Apps logs (ACA variant) | Reader |

Notes:
- Everything except `connect-vm.sh` and `db-connect.sh` works over the Azure
  management plane and needs no VPN/Bastion.
- `db-connect.sh` and interactive `connect-vm.sh` need a private path into the
  VNet — see the Bastion / Tailscale private-access setup.
- `backup-exec.sh` mangles `/usr/...` paths under Git Bash on Windows; run it
  from WSL/PowerShell.
