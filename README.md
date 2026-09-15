# assurance-test platform

Three-tier Node.js platform (web -> api -> db) with continuous delivery on Azure.

- `app/`     application services (web, api)
- `infra/`   Terraform infrastructure
- `scripts/` bootstrap, runtime, backup, smoke-test helpers
- `.github/workflows/` CI/CD pipeline

See `infra/README.md` for provisioning and `scripts/` for operations.
