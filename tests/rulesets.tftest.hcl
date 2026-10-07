# Exercises all 5 github_repository_ruleset resources in main.rules.tf,
# including the conventional_commits compound-AND gate and the
# ruleset_bypass_actors scoping logic in locals.tf.

mock_provider "github" {}

variables {
  repo_name = "test-repo"
}

run "branch_protection_defaults" {
  command = plan
  assert {
    condition     = github_repository_ruleset.branch_protection.name == "test-repo-branch-protection"
    error_message = "branch_protection ruleset name should be derived from repo_name"
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.target == "branch"
    error_message = "branch_protection ruleset should target branch"
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].pull_request[0].required_approving_review_count == 1
    error_message = "default pull_request_reviewer_count (1) should flow through to required_approving_review_count"
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].required_linear_history == false
    error_message = "required_linear_history should be false by default (allow_merge_commit defaults to true)"
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.rules[0].copilot_code_review) == 1
    error_message = "copilot_code_review block should be present by default (enable_automatic_copilot_review defaults to true)"
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.rules[0].required_status_checks) == 1
    error_message = "required_status_checks block should be present by default (required_status_checks has a default entry)"
  }
  assert {
    condition     = contains([for c in github_repository_ruleset.branch_protection.rules[0].required_status_checks[0].required_check : c.context], "terraform-pull-request")
    error_message = "default required_status_checks entry 'terraform-pull-request' should be present"
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.conditions[0].ref_name[0].include) == 1 && github_repository_ruleset.branch_protection.conditions[0].ref_name[0].include[0] == "~DEFAULT_BRANCH"
    error_message = "branch_protection should scope to the default branch"
  }
}

run "linear_history_toggle" {
  command = plan
  variables {
    allow_merge_commit = false
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].required_linear_history == true
    error_message = "required_linear_history should be true when allow_merge_commit is false"
  }
}

run "copilot_review_disabled" {
  command = plan
  variables {
    enable_automatic_copilot_review = false
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.rules[0].copilot_code_review) == 0
    error_message = "copilot_code_review block should be absent when enable_automatic_copilot_review is false"
  }
}

run "copilot_review_draft_prs_flag" {
  command = plan
  variables {
    enable_automatic_copilot_review_draft_prs = true
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].copilot_code_review[0].review_on_push == true
    error_message = "review_on_push should reflect enable_automatic_copilot_review_draft_prs"
  }
}

run "required_status_checks_empty" {
  command = plan
  variables {
    required_status_checks = []
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.rules[0].required_status_checks) == 0
    error_message = "required_status_checks block should be absent when the list is empty"
  }
}

run "commit_signing_enabled" {
  command = plan
  variables {
    require_signed_commits = true
    require_signed_tags    = true
  }
  assert {
    condition     = length(github_repository_ruleset.commit_signing) == 1
    error_message = "commit_signing ruleset should be created when require_signed_commits is true"
  }
  assert {
    condition     = github_repository_ruleset.commit_signing[0].target == "branch"
    error_message = "commit_signing ruleset should target branch"
  }
  assert {
    condition     = github_repository_ruleset.commit_signing[0].conditions[0].ref_name[0].include[0] == "~ALL"
    error_message = "commit_signing ruleset should scope to all branches"
  }
  assert {
    condition     = length(github_repository_ruleset.commit_signing_tags) == 1
    error_message = "commit_signing_tags ruleset should be created when require_signed_tags is true"
  }
  assert {
    condition     = github_repository_ruleset.commit_signing_tags[0].target == "tag"
    error_message = "commit_signing_tags ruleset should target tag"
  }
}

run "signing_rulesets_default_enabled" {
  command = plan
  assert {
    condition     = length(github_repository_ruleset.commit_signing) == 1 && length(github_repository_ruleset.commit_signing_tags) == 1
    error_message = "commit and tag signing rulesets should be created by default"
  }
}

run "signing_rulesets_disabled" {
  command = plan
  variables {
    require_signed_commits = false
    require_signed_tags    = false
  }
  assert {
    condition     = length(github_repository_ruleset.commit_signing) == 0
    error_message = "commit_signing ruleset should not be created when disabled"
  }
  assert {
    condition     = length(github_repository_ruleset.commit_signing_tags) == 0
    error_message = "commit_signing_tags ruleset should not be created when disabled"
  }
}

run "conventional_commits_both_true" {
  command = plan
  variables {
    require_conventional_commits = true
    enterprise_features_enabled  = true
  }
  assert {
    condition     = length(github_repository_ruleset.conventional_commits) == 1
    error_message = "conventional_commits ruleset should be created when both gates are true"
  }
  assert {
    condition     = github_repository_ruleset.conventional_commits[0].conditions[0].ref_name[0].exclude[0] == "~DEFAULT_BRANCH"
    error_message = "conventional_commits ruleset should exclude the default branch"
  }
  assert {
    condition     = github_repository_ruleset.conventional_commits[0].rules[0].commit_message_pattern[0].pattern == var.conventional_commit_pattern
    error_message = "conventional_commits ruleset should use local.conventional_commit_pattern"
  }
}

run "conventional_commits_flag_false" {
  command = plan
  variables {
    require_conventional_commits = false
    enterprise_features_enabled  = true
  }
  assert {
    condition     = length(github_repository_ruleset.conventional_commits) == 0
    error_message = "conventional_commits ruleset should not be created when require_conventional_commits is false"
  }
}

run "conventional_commits_enterprise_false" {
  command = plan
  variables {
    require_conventional_commits = true
    enterprise_features_enabled  = false
  }
  assert {
    condition     = length(github_repository_ruleset.conventional_commits) == 0
    error_message = "conventional_commits ruleset should not be created when enterprise_features_enabled is false"
  }
}

run "conventional_commits_both_false" {
  command = plan
  variables {
    require_conventional_commits = false
    enterprise_features_enabled  = false
  }
  assert {
    condition     = length(github_repository_ruleset.conventional_commits) == 0
    error_message = "conventional_commits ruleset should not be created when both gates are false"
  }
}

run "push_protection_disabled" {
  command = plan
  assert {
    condition     = length(github_repository_ruleset.push_protection) == 0
    error_message = "push_protection ruleset should not be created when disabled"
  }
}

run "push_protection_all_restrictions" {
  command = plan
  variables {
    push_ruleset_enabled                     = true
    push_ruleset_file_path_restrictions      = ["secrets/*"]
    push_ruleset_max_file_size_mb            = 10
    push_ruleset_file_extension_restrictions = [".exe"]
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection) == 1
    error_message = "push_protection ruleset should be created when push_ruleset_enabled is true"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].file_path_restriction) == 1 && github_repository_ruleset.push_protection[0].rules[0].file_path_restriction[0].restricted_file_paths[0] == "secrets/*"
    error_message = "file_path_restriction should reflect push_ruleset_file_path_restrictions"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].max_file_size) == 1 && github_repository_ruleset.push_protection[0].rules[0].max_file_size[0].max_file_size == 10
    error_message = "max_file_size should reflect push_ruleset_max_file_size_mb"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].file_extension_restriction) == 1 && contains(github_repository_ruleset.push_protection[0].rules[0].file_extension_restriction[0].restricted_file_extensions, ".exe")
    error_message = "file_extension_restriction should reflect push_ruleset_file_extension_restrictions"
  }
}

run "push_protection_enabled_no_restrictions" {
  command = plan
  variables {
    push_ruleset_enabled = true
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection) == 1
    error_message = "push_protection ruleset should still be created with no restrictions configured"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].file_path_restriction) == 0
    error_message = "file_path_restriction should be absent when push_ruleset_file_path_restrictions is empty"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].max_file_size) == 0
    error_message = "max_file_size should be absent when push_ruleset_max_file_size_mb is null"
  }
  assert {
    condition     = length(github_repository_ruleset.push_protection[0].rules[0].file_extension_restriction) == 0
    error_message = "file_extension_restriction should be absent when push_ruleset_file_extension_restrictions is empty"
  }
}

run "bypass_actor_scoping" {
  command = plan
  variables {
    require_signed_commits = true
    ruleset_bypass_actors = [
      {
        actor_type  = "OrganizationAdmin"
        actor_id    = 1
        bypass_mode = "always"
      },
      {
        actor_type  = "Team"
        actor_id    = 2
        bypass_mode = "always"
        rulesets    = ["commit_signing"]
      }
    ]
  }
  assert {
    condition     = length(local.ruleset_bypass_actors_by_ruleset["branch_protection"]) == 1
    error_message = "only the unscoped (rulesets=null) actor should apply to branch_protection"
  }
  assert {
    condition     = length(local.ruleset_bypass_actors_by_ruleset["commit_signing"]) == 2
    error_message = "both the unscoped actor and the commit_signing-scoped actor should apply to commit_signing"
  }
  assert {
    condition     = length(github_repository_ruleset.branch_protection.bypass_actors) == 1
    error_message = "branch_protection ruleset should have exactly 1 bypass_actors block"
  }
  assert {
    condition     = length(github_repository_ruleset.commit_signing[0].bypass_actors) == 2
    error_message = "commit_signing ruleset should have exactly 2 bypass_actors blocks"
  }
}

run "branch_protection_review_and_status_check_toggles" {
  command = plan
  variables {
    require_code_owner_review     = false
    require_last_push_approval    = false
    strict_required_status_checks = true
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].pull_request[0].require_code_owner_review == false && github_repository_ruleset.branch_protection.rules[0].pull_request[0].require_last_push_approval == false
    error_message = "code owner review and last push approval should follow their variables"
  }
  assert {
    condition     = github_repository_ruleset.branch_protection.rules[0].required_status_checks[0].strict_required_status_checks_policy == true
    error_message = "strict status checks should follow strict_required_status_checks"
  }
}
