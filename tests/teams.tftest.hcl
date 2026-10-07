# Exercises main.teams.tf plus the team-related locals (teams_to_create,
# existing_teams, teams_with_saml_sync, teams_with_emu_mapping,
# emu_external_group_id_by_name, team_ids_by_key, team_slugs_by_key,
# team_members_flat) and the team_ids/team_slugs outputs.
#
# data.github_team.existing and data.github_external_groups.this are real
# API-backed data sources - override_data pins them to deterministic values
# so the merge/lookup logic can be asserted against known results.

mock_provider "github" {}

variables {
  repo_name = "test-repo"
}

run "created_team_wiring" {
  command = plan
  variables {
    teams = {
      platform = {
        permission  = "admin"
        create      = true
        name        = "platform"
        description = "Platform team"
        privacy     = "secret"
      }
    }
  }
  assert {
    condition     = length(github_team.this) == 1
    error_message = "github_team.this should contain exactly the created team"
  }
  assert {
    condition     = github_team.this["platform"].name == "platform" && github_team.this["platform"].privacy == "secret"
    error_message = "created team attributes should pass through from var.teams"
  }
  assert {
    condition     = length(data.github_team.existing) == 0
    error_message = "no existing-team lookups should occur when every team has create = true"
  }
  assert {
    condition     = length(github_team_repository.this) == 1
    error_message = "github_team_repository should attach every team in var.teams regardless of create"
  }
  assert {
    condition     = github_team_repository.this["platform"].permission == "admin"
    error_message = "team repository attachment permission should pass through"
  }
}

run "existing_team_lookup_and_merge" {
  command = plan
  variables {
    teams = {
      readers = {
        permission = "pull"
        create     = false
      }
    }
  }
  override_data {
    target          = data.github_team.existing["readers"]
    override_during = plan
    values = {
      id   = "555"
      slug = "readers"
    }
  }
  assert {
    condition     = length(github_team.this) == 0
    error_message = "no teams should be created when create = false"
  }
  assert {
    condition     = length(data.github_team.existing) == 1
    error_message = "existing-team lookup should occur for the readers team"
  }
  assert {
    condition     = local.team_ids_by_key["readers"] == "555"
    error_message = "team_ids_by_key should resolve the existing team's id from the data source"
  }
  assert {
    condition     = local.team_slugs_by_key["readers"] == "readers"
    error_message = "team_slugs_by_key should resolve the existing team's slug from the data source"
  }
  assert {
    condition     = output.team_ids["readers"] == "555"
    error_message = "team_ids output should reflect the existing team's id"
  }
  assert {
    condition     = github_team_repository.this["readers"].team_id == "readers"
    error_message = "team_repository attachment should use the resolved existing team slug"
  }
}

run "mixed_created_and_existing_merge" {
  command = plan
  variables {
    teams = {
      platform = {
        permission = "admin"
        create     = true
        name       = "platform"
      }
      readers = {
        permission = "pull"
        create     = false
      }
    }
  }
  override_resource {
    target          = github_team.this["platform"]
    override_during = plan
    values = {
      id   = "111"
      slug = "platform"
    }
  }
  override_data {
    target          = data.github_team.existing["readers"]
    override_during = plan
    values = {
      id   = "555"
      slug = "readers"
    }
  }
  assert {
    condition     = length(github_team.this) == 1
    error_message = "only the create=true team should be created"
  }
  assert {
    condition     = length(data.github_team.existing) == 1
    error_message = "only the create=false team should be looked up"
  }
  assert {
    condition     = local.team_ids_by_key["platform"] == "111" && local.team_ids_by_key["readers"] == "555" && length(local.team_ids_by_key) == 2
    error_message = "team_ids_by_key should merge created and existing teams with exactly these two keys"
  }
  assert {
    condition     = length(github_team_repository.this) == 2
    error_message = "github_team_repository should attach both teams regardless of create"
  }
}

run "team_members_flat_and_membership" {
  command = plan
  variables {
    teams = {
      platform = {
        permission = "admin"
        create     = true
        name       = "platform"
        members = [
          { username = "alice" },
          { username = "bob", role = "maintainer" }
        ]
      }
    }
  }
  override_resource {
    target          = github_team.this["platform"]
    override_during = plan
    values = {
      id   = "111"
      slug = "platform"
    }
  }
  assert {
    condition     = local.team_members_flat["platform:alice"].role == "member" && local.team_members_flat["platform:bob"].role == "maintainer"
    error_message = "team_members_flat should flatten members with the default 'member' role applied when unset"
  }
  assert {
    condition     = length(github_team_membership.this) == 2
    error_message = "github_team_membership should contain one entry per flattened member"
  }
  assert {
    condition     = github_team_membership.this["platform:bob"].role == "maintainer" && github_team_membership.this["platform:bob"].team_id == "111"
    error_message = "github_team_membership should use the resolved team id (via team_ids_by_key) and the member's role"
  }
}

run "saml_team_sync_mapping" {
  command = plan
  variables {
    identity_provider_model = "saml_team_sync"
    teams = {
      platform = {
        permission     = "admin"
        create         = true
        name           = "platform"
        idp_group_id   = "aaaa-bbbb"
        idp_group_name = "Platform Engineers"
      }
    }
  }
  override_resource {
    target          = github_team.this["platform"]
    override_during = plan
    values = {
      id   = "111"
      slug = "platform"
    }
  }
  assert {
    condition     = length(github_team_sync_group_mapping.this) == 1
    error_message = "github_team_sync_group_mapping should be created under saml_team_sync when idp_group_name is set"
  }
  assert {
    condition     = one(github_team_sync_group_mapping.this["platform"].group).group_id == "aaaa-bbbb" && one(github_team_sync_group_mapping.this["platform"].group).group_name == "Platform Engineers"
    error_message = "github_team_sync_group_mapping should pass through idp_group_id/idp_group_name"
  }
  assert {
    condition     = one(github_team_sync_group_mapping.this["platform"].group).group_description == "Entra ID group synced to GitHub team platform"
    error_message = "group_description should default to the documented coalesce() fallback string"
  }
  assert {
    condition     = length(github_emu_group_mapping.this) == 0
    error_message = "github_emu_group_mapping should stay empty under saml_team_sync"
  }
  assert {
    condition     = local.emu_external_group_id_by_name == {}
    error_message = "emu_external_group_id_by_name should stay empty under saml_team_sync"
  }
}

run "emu_group_mapping_resolution" {
  command = plan
  variables {
    identity_provider_model = "enterprise_managed_users"
    teams = {
      platform = {
        permission     = "admin"
        create         = true
        name           = "platform"
        idp_group_name = "Platform Engineers"
      }
    }
  }
  override_resource {
    target          = github_team.this["platform"]
    override_during = plan
    values = {
      id   = "111"
      slug = "platform"
    }
  }
  override_data {
    target          = data.github_external_groups.this[0]
    override_during = plan
    values = {
      external_groups = [
        {
          group_id   = 4242
          group_name = "Platform Engineers"
          updated_at = "2026-01-01T00:00:00Z"
        }
      ]
    }
  }
  assert {
    condition     = local.emu_external_group_id_by_name["Platform Engineers"] == 4242
    error_message = "emu_external_group_id_by_name should resolve the group id by name from the external groups data source"
  }
  assert {
    condition     = length(github_emu_group_mapping.this) == 1
    error_message = "github_emu_group_mapping should be created under enterprise_managed_users when idp_group_name is set"
  }
  assert {
    condition     = github_emu_group_mapping.this["platform"].group_id == 4242
    error_message = "github_emu_group_mapping should use the resolved group id"
  }
  assert {
    condition     = length(github_team_sync_group_mapping.this) == 0
    error_message = "github_team_sync_group_mapping should stay empty under enterprise_managed_users"
  }
}

run "identity_provider_model_standalone_no_mappings" {
  command = plan
  variables {
    teams = {
      platform = {
        permission = "admin"
        create     = true
        name       = "platform"
        members = [
          { username = "alice" }
        ]
      }
    }
  }
  override_resource {
    target          = github_team.this["platform"]
    override_during = plan
    values = {
      id   = "111"
      slug = "platform"
    }
  }
  assert {
    condition     = length(github_team_sync_group_mapping.this) == 0
    error_message = "github_team_sync_group_mapping should never activate under standalone"
  }
  assert {
    condition     = length(github_emu_group_mapping.this) == 0
    error_message = "github_emu_group_mapping should never activate under standalone"
  }
  assert {
    condition     = length(data.github_external_groups.this) == 0
    error_message = "data.github_external_groups.this should not be read under standalone"
  }
}
