environment               = "prod"
high_availability_enabled = true
db_sku                    = "GP_Standard_D2ds_v4"
vm_sku                    = "Standard_B2s"
web_instance_count        = 2
api_instance_count        = 2
# Real destination is injected at deploy time (TF_VAR_alert_email / -var); placeholder here.
alert_email               = "platform-alerts@example.com"
purge_protection_enabled  = true
log_daily_quota_gb        = 5
bastion_enabled           = true
# subscription_id         = "<prod-subscription-guid>"   # set for multi-subscription
