# Exercises every variable validation rule in variables.required.tf and
# variables.optional.tf via expect_failures. Each run block is crafted to
# trip exactly one rule while satisfying every other rule on that variable,
# so a passing test unambiguously proves that one rule fired.
#
# Validations run before any resource/data expansion, so these never need
# the github provider - mock_provider is declared anyway for consistency
# and in case a future rule depends on a local that reaches a data source.

mock_provider "github" {}

variables {
  repo_name = "test-repo"
}

run "repo_name_invalid_chars" {
  command = plan
  variables {
    repo_name = "bad name!"
  }
  expect_failures = [var.repo_name]
}

run "repo_name_too_long" {
  command = plan
  variables {
    repo_name = join("", [for i in range(101) : "a"])
  }
  expect_failures = [var.repo_name]
}

run "description_too_long" {
  command = plan
  variables {
    description = join("", [for i in range(400) : "a"])
  }
  expect_failures = [var.description]
}

run "visibility_invalid" {
  command = plan
  variables {
    visibility = "public"
  }
  expect_failures = [var.visibility]
}

run "squash_merge_commit_title_invalid" {
  command = plan
  variables {
    squash_merge_commit_title = "X"
  }
  expect_failures = [var.squash_merge_commit_title]
}

run "squash_merge_commit_message_invalid" {
  command = plan
  variables {
    squash_merge_commit_message = "X"
  }
  expect_failures = [var.squash_merge_commit_message]
}

run "squash_cross_check_invalid" {
  command = plan
  variables {
    squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
    squash_merge_commit_message = "PR_BODY"
  }
  expect_failures = [var.squash_merge_commit_message]
}

run "merge_commit_title_invalid" {
  command = plan
  variables {
    merge_commit_title = "X"
  }
  expect_failures = [var.merge_commit_title]
}

run "merge_commit_message_invalid" {
  command = plan
  variables {
    merge_commit_message = "X"
  }
  expect_failures = [var.merge_commit_message]
}

run "merge_cross_check_invalid" {
  command = plan
  variables {
    merge_commit_title   = "MERGE_MESSAGE"
    merge_commit_message = "PR_BODY"
  }
  expect_failures = [var.merge_commit_message]
}

run "topics_too_many" {
  command = plan
  variables {
    topics = [for i in range(21) : "t${i}"]
  }
  expect_failures = [var.topics]
}

run "topics_invalid_pattern" {
  command = plan
  variables {
    topics = ["Bad_Topic"]
  }
  expect_failures = [var.topics]
}

run "issue_labels_bad_color" {
  command = plan
  variables {
    issue_labels = {
      broken = {
        color       = "zzzzzz"
        description = "bad color"
      }
    }
  }
  expect_failures = [var.issue_labels]
}

run "issue_labels_description_too_long" {
  command = plan
  variables {
    issue_labels = {
      broken = {
        color       = "112233"
        description = join("", [for i in range(101) : "a"])
      }
    }
  }
  expect_failures = [var.issue_labels]
}

run "dependabot_secret_bad_key" {
  command = plan
  variables {
    dependabot_secrets = {
      "1BAD" = {}
    }
  }
  expect_failures = [var.dependabot_secrets]
}

run "dependabot_secret_github_prefix" {
  command = plan
  variables {
    dependabot_secrets = {
      "GITHUB_TOKEN" = {}
    }
  }
  expect_failures = [var.dependabot_secrets]
}

run "dependabot_secret_github_prefix_case_insensitive" {
  command = plan
  variables {
    dependabot_secrets = {
      "github_token" = {}
    }
  }
  expect_failures = [var.dependabot_secrets]
}

run "bypass_actor_invalid_actor_type" {
  command = plan
  variables {
    ruleset_bypass_actors = [
      {
        actor_type = "NotAType"
        actor_id   = 1
      }
    ]
  }
  expect_failures = [var.ruleset_bypass_actors]
}

run "bypass_actor_invalid_bypass_mode" {
  command = plan
  variables {
    ruleset_bypass_actors = [
      {
        actor_type  = "OrganizationAdmin"
        actor_id    = 1
        bypass_mode = "sometimes"
      }
    ]
  }
  expect_failures = [var.ruleset_bypass_actors]
}

run "bypass_actor_invalid_ruleset_name" {
  command = plan
  variables {
    ruleset_bypass_actors = [
      {
        actor_type = "OrganizationAdmin"
        actor_id   = 1
        rulesets   = ["not_a_real_ruleset"]
      }
    ]
  }
  expect_failures = [var.ruleset_bypass_actors]
}

run "pull_request_reviewer_count_negative" {
  command = plan
  variables {
    pull_request_reviewer_count = -1
  }
  expect_failures = [var.pull_request_reviewer_count]
}

run "push_ruleset_max_file_size_too_low" {
  command = plan
  variables {
    push_ruleset_max_file_size_mb = 0
  }
  expect_failures = [var.push_ruleset_max_file_size_mb]
}

run "push_ruleset_max_file_size_too_high" {
  command = plan
  variables {
    push_ruleset_max_file_size_mb = 101
  }
  expect_failures = [var.push_ruleset_max_file_size_mb]
}

run "oidc_claim_key_bad_pattern" {
  command = plan
  variables {
    oidc_subject_claim_keys = ["bad key!"]
  }
  expect_failures = [var.oidc_subject_claim_keys]
}

run "oidc_subject_claim_keys_null_is_accepted" {
  command = plan
  variables {
    oidc_subject_claim_keys = null
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.use_default == true
    error_message = "oidc_subject_claim_keys = null should be accepted and drive use_default = true"
  }
}

run "actions_access_level_invalid" {
  command = plan
  variables {
    actions_access_level = "team"
  }
  expect_failures = [var.actions_access_level]
}

run "identity_provider_model_invalid" {
  command = plan
  variables {
    identity_provider_model = "azure_ad"
  }
  expect_failures = [var.identity_provider_model]
}

run "teams_permission_empty" {
  command = plan
  variables {
    teams = {
      foo = {
        permission = ""
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_privacy_invalid" {
  command = plan
  variables {
    teams = {
      foo = {
        permission = "pull"
        privacy    = "public"
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_create_requires_name_invalid" {
  command = plan
  variables {
    teams = {
      foo = {
        permission = "admin"
        create     = true
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_parent_and_idp_conflict_invalid" {
  command = plan
  variables {
    teams = {
      foo = {
        permission     = "pull"
        parent_team_id = "123"
        idp_group_name = "Some Group"
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_idp_group_id_without_name_invalid" {
  command = plan
  variables {
    teams = {
      foo = {
        permission   = "pull"
        idp_group_id = "aaaa-bbbb"
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_saml_requires_idp_group_id_invalid" {
  command = plan
  variables {
    identity_provider_model = "saml_team_sync"
    teams = {
      foo = {
        permission     = "pull"
        idp_group_name = "Some Group"
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_idp_group_name_under_standalone_invalid" {
  command = plan
  variables {
    identity_provider_model = "standalone"
    teams = {
      foo = {
        permission     = "pull"
        idp_group_name = "Some Group"
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_idp_group_name_and_members_conflict_invalid" {
  command = plan
  variables {
    identity_provider_model = "saml_team_sync"
    teams = {
      foo = {
        permission     = "pull"
        idp_group_id   = "aaaa-bbbb"
        idp_group_name = "Some Group"
        members = [
          { username = "alice" }
        ]
      }
    }
  }
  expect_failures = [var.teams]
}

run "teams_member_role_invalid" {
  command = plan
  variables {
    teams = {
      foo = {
        permission = "pull"
        members = [
          { username = "alice", role = "owner" }
        ]
      }
    }
  }
  expect_failures = [var.teams]
}

run "bypass_actor_missing_actor_id" {
  command = plan
  variables {
    ruleset_bypass_actors = [
      {
        actor_type = "Team"
      }
    ]
  }
  expect_failures = [var.ruleset_bypass_actors]
}

run "bypass_actor_without_id_allowed_for_org_admin" {
  command = plan
  variables {
    ruleset_bypass_actors = [
      {
        actor_type = "OrganizationAdmin"
      }
    ]
  }
}

run "no_merge_method_enabled" {
  command = plan
  variables {
    allow_merge_commit = false
    allow_squash_merge = false
    allow_rebase_merge = false
  }
  expect_failures = [var.allow_merge_commit]
}

run "dependabot_updates_require_vulnerability_alerts" {
  command = plan
  variables {
    enable_vulnerability_alerts        = false
    enable_dependabot_security_updates = true
  }
  expect_failures = [var.enable_dependabot_security_updates]
}

run "default_branch_name_invalid" {
  command = plan
  variables {
    default_branch_name = "bad..name"
  }
  expect_failures = [var.default_branch_name]
}

run "allowed_actions_invalid" {
  command = plan
  variables {
    allowed_actions = "some"
  }
  expect_failures = [var.allowed_actions]
}

run "allowed_actions_selected_requires_config" {
  command = plan
  variables {
    allowed_actions = "selected"
  }
  expect_failures = [var.allowed_actions_config]
}

run "allowed_actions_config_requires_selected" {
  command = plan
  variables {
    allowed_actions_config = { github_owned_allowed = true }
  }
  expect_failures = [var.allowed_actions_config]
}

run "oidc_claim_keys_duplicates" {
  command = plan
  variables {
    oidc_subject_claim_keys = ["repository", "repository"]
  }
  expect_failures = [var.oidc_subject_claim_keys]
}
