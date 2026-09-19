# Onboarding

Access to an environment is granted through Entra ID group membership, not
per-user role assignments. The groups, their scoped roles, and the database
Entra admin are defined in Terraform (`infra/modules/rbac`) and created when
`rbac_enabled = true` for the environment.

## Groups and rights

| Role group   | Azure rights                                                        |
| ------------ | ------------------------------------------------------------------- |
| `readonly`   | Reader on the resource group                                        |
| `dev`        | Custom app-operator: read all, restart/upgrade the app scale sets, query logs |
| `ops`        | Contributor on the resource group                                   |
| `dba`        | Custom db-operator (restart/start/stop, server parameters) + PostgreSQL Entra admin |
| `security`   | Security Reader + Reader on the resource group                      |

Group names follow the convention `astst-<env>-<role>` (e.g. `astst-prod-dba`).

## Provisioning the groups

Creating Entra groups needs Microsoft Graph `Group.ReadWrite.All`. The OIDC CI
identity does not hold it by default, so apply the RBAC layer locally under an
Entra directory admin:

```bash
cd infra
terraform apply -var-file=environments/prod.tfvars -var rbac_enabled=true \
  -var web_image_tag=<sha> -var api_image_tag=<sha> -var 'deployer_ip_rules=["<your-ip>"]'
```

(Alternatively grant the CI identity admin-consented `Group.ReadWrite.All` and
set `rbac_enabled = true` in the env tfvars.) Entra groups and custom roles are
tenant-level objects and persist after `terraform destroy` -- remove them
explicitly if you tear the tenant down.

## Adding / removing people

```bash
ENV=prod ./onboard-user.sh alice@example.com dev
ENV=prod ./offboard-user.sh alice@example.com dev   # one role
ENV=prod ./offboard-user.sh alice@example.com         # all roles
```

Both scripts need only `az login` as someone allowed to manage the group's
membership; they do not touch Terraform state.
