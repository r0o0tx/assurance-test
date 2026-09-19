output "group_ids" {
  description = "Role slug -> Entra group object id, for onboarding automation."
  value       = { for slug, g in azuread_group.role : slug => g.object_id }
}

output "group_names" {
  description = "Role slug -> Entra group display name."
  value       = { for slug, g in azuread_group.role : slug => g.display_name }
}
