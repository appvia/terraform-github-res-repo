# Exercises main.actions.tf and main.labels.tf.

mock_provider "github" {}

variables {
  repo_name = "test-repo"
}

run "actions_permissions_and_access_level_defaults" {
  command = plan
  assert {
    condition     = github_actions_repository_permissions.this.enabled == true
    error_message = "actions should be enabled"
  }
  assert {
    condition     = github_actions_repository_permissions.this.sha_pinning_required == true
    error_message = "sha_pinning_required should always be true"
  }
  assert {
    condition     = github_actions_repository_permissions.this.allowed_actions == "all"
    error_message = "allowed_actions should default to all"
  }
  assert {
    condition     = github_actions_repository_access_level.this.access_level == "none"
    error_message = "actions_access_level should default to none"
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.use_default == false
    error_message = "use_default should be false by default, since oidc_subject_claim_keys defaults to a non-null list"
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.include_claim_keys == var.oidc_subject_claim_keys
    error_message = "include_claim_keys should default to the documented oidc_subject_claim_keys list"
  }
}

run "actions_access_level_override" {
  command = plan
  variables {
    actions_access_level = "organization"
  }
  assert {
    condition     = github_actions_repository_access_level.this.access_level == "organization"
    error_message = "actions_access_level should pass through the override"
  }
}

run "oidc_custom_claim_keys" {
  command = plan
  variables {
    oidc_subject_claim_keys = ["repository", "ref"]
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.use_default == false
    error_message = "use_default should be false when a custom claim key list is supplied"
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.include_claim_keys == var.oidc_subject_claim_keys
    error_message = "include_claim_keys should reflect the custom list"
  }
}

run "oidc_use_default_true" {
  command = plan
  variables {
    oidc_subject_claim_keys = null
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.use_default == true
    error_message = "use_default should be true when oidc_subject_claim_keys is explicitly null"
  }
}

run "issue_labels_defaults" {
  command = plan
  assert {
    condition     = length(github_issue_label.this) == 4
    error_message = "the default issue_labels map should create 4 labels"
  }
  assert {
    condition     = github_issue_label.this["terraform-drift"].color == "FBCA04" && github_issue_label.this["terraform-drift"].description == "Live infrastructure has drifted from the Terraform configuration"
    error_message = "terraform-drift label should match the documented default"
  }
  assert {
    condition     = github_issue_label.this["terraform-bug"].color == "D93F0B" && github_issue_label.this["terraform-bug"].description == "Something is broken in the Terraform configuration or module"
    error_message = "terraform-bug label should match the documented default"
  }
  assert {
    condition     = github_issue_label.this["workflow-bug"].color == "B60205" && github_issue_label.this["workflow-bug"].description == "Something is broken in a GitHub Actions workflow"
    error_message = "workflow-bug label should match the documented default"
  }
  assert {
    condition     = github_issue_label.this["security"].color == "EE0701" && github_issue_label.this["security"].description == "Security-related issue, e.g. secret scanning, vulnerability alerts, or Dependabot"
    error_message = "security label should match the documented default"
  }
}

run "issue_labels_empty_override" {
  command = plan
  variables {
    issue_labels = {}
  }
  assert {
    condition     = length(github_issue_label.this) == 0
    error_message = "issue_labels = {} should create no labels"
  }
}

run "issue_labels_custom" {
  command = plan
  variables {
    issue_labels = {
      "my-label" = {
        color       = "112233"
        description = "custom"
      }
    }
  }
  assert {
    condition     = length(github_issue_label.this) == 1
    error_message = "a single custom label should be created"
  }
  assert {
    condition     = github_issue_label.this["my-label"].name == "my-label"
    error_message = "the label name should be driven by the map key (each.key), not a name field on the object"
  }
  assert {
    condition     = github_issue_label.this["my-label"].color == "112233" && github_issue_label.this["my-label"].description == "custom"
    error_message = "custom label color/description should pass through"
  }
}

run "oidc_empty_list_uses_default" {
  command = plan
  variables {
    oidc_subject_claim_keys = []
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.use_default == true
    error_message = "an empty claim key list should fall back to GitHub's default subject claim"
  }
}

run "oidc_claim_key_order_preserved" {
  command = plan
  variables {
    oidc_subject_claim_keys = ["repository", "job_workflow_ref", "environment"]
  }
  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this.include_claim_keys == tolist(["repository", "job_workflow_ref", "environment"])
    error_message = "claim key order must be preserved - it determines the layout of the sub claim"
  }
}

run "allowed_actions_selected" {
  command = plan
  variables {
    allowed_actions        = "selected"
    allowed_actions_config = { github_owned_allowed = true, patterns_allowed = ["hashicorp/*"] }
  }
  assert {
    condition     = github_actions_repository_permissions.this.allowed_actions == "selected" && length(github_actions_repository_permissions.this.allowed_actions_config) == 1
    error_message = "allowed_actions_config block should be rendered when allowed_actions = selected"
  }
}
