resource "github_team" "this" {
  for_each       = local.teams_to_create
  name           = each.value.name
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = each.value.parent_team_id
}

data "github_team" "existing" {
  for_each = local.existing_teams
  slug     = each.key
}

# Only read when EMU model is active - needed to resolve idp_group_name to
# GitHub's SCIM-provisioned numeric external-group ID.
data "github_external_groups" "this" {
  count = var.identity_provider_model == "enterprise_managed_users" ? 1 : 0
}

# Connecting an existing team to an IdP group requires the team to currently
# have zero members - a GitHub API constraint Terraform can't work around.
resource "github_team_sync_group_mapping" "this" {
  for_each  = local.teams_with_saml_sync
  team_slug = local.team_slugs_by_key[each.key]
  group {
    group_id          = each.value.idp_group_id
    group_name        = each.value.idp_group_name
    group_description = coalesce(each.value.idp_group_description, "Entra ID group synced to GitHub team ${each.key}")
  }
}

# Same zero-members-on-connect constraint as github_team_sync_group_mapping.
resource "github_emu_group_mapping" "this" {
  for_each  = local.teams_with_emu_mapping
  team_slug = local.team_slugs_by_key[each.key]
  group_id  = local.emu_external_group_id_by_name[each.value.idp_group_name]
  lifecycle {
    precondition {
      condition     = contains(keys(local.emu_external_group_id_by_name), each.value.idp_group_name)
      error_message = "idp_group_name \"${each.value.idp_group_name}\" on team \"${each.key}\" was not found among GitHub's SCIM-provisioned external groups. Check SCIM provisioning has synced the Entra group."
    }
  }
}

resource "github_team_membership" "this" {
  for_each = local.team_members_flat
  team_id  = local.team_ids_by_key[each.value.team_key]
  username = each.value.username
  role     = each.value.role
}

resource "github_team_repository" "this" {
  for_each   = var.teams
  team_id    = local.team_slugs_by_key[each.key] # accepts ID or slug; slug is stable
  repository = github_repository.this.name
  permission = each.value.permission
}
