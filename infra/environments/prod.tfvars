environment               = "prod"
high_availability_enabled = true
db_sku                    = "GP_Standard_D2ds_v4"
vm_sku                    = "Standard_B2s"
web_instance_count        = 2
api_instance_count        = 2
# Real destination is injected at deploy time (TF_VAR_alert_email / -var); placeholder here.
alert_email               = "platform-alerts@example.com"
# Test-cycle only (WS6 activation branch): disabled so CI destroy.yml can purge the
# vault cleanly without the deletedVaults/read permission gap. Reset to true on main.
purge_protection_enabled  = false
log_daily_quota_gb        = 5
# Developer-SKU Bastion races VNet provisioning on a cold deploy; keep it off
# until that create-ordering is handled. Module code is validated and ready.
bastion_enabled           = false
# subscription_id         = "<prod-subscription-guid>"   # set for multi-subscription
