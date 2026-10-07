# Exercises github_repository.this, github_branch_default.this,
# github_repository_vulnerability_alerts.this,
# github_repository_dependabot_security_updates.this,
# random_password.dependabot_secret / github_dependabot_secret.this, and the
# repository_* outputs.

mock_provider "github" {}

variables {
  repo_name = "test-repo"
}

run "defaults_plan" {
  command = plan
  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "default visibility should be private"
  }
  assert {
    condition     = github_repository.this.has_issues == true
    error_message = "issues should be enabled by default"
  }
  assert {
    condition     = github_repository.this.has_wiki == false
    error_message = "wiki should be disabled by default"
  }
  assert {
    condition     = github_repository.this.has_discussions == false
    error_message = "discussions should be disabled by default"
  }
  assert {
    condition     = github_repository.this.allow_merge_commit && github_repository.this.allow_squash_merge && github_repository.this.allow_rebase_merge && github_repository.this.allow_auto_merge
    error_message = "all merge methods and auto-merge should be allowed by default"
  }
  assert {
    condition     = github_repository.this.squash_merge_commit_title == "COMMIT_OR_PR_TITLE" && github_repository.this.squash_merge_commit_message == "COMMIT_MESSAGES"
    error_message = "default squash merge title/message should pass through when allow_squash_merge is true"
  }
  assert {
    condition     = github_repository.this.merge_commit_title == "MERGE_MESSAGE" && github_repository.this.merge_commit_message == "PR_TITLE"
    error_message = "default merge commit title/message should pass through when allow_merge_commit is true"
  }
  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "delete_branch_on_merge should default to true"
  }
  assert {
    condition     = length(github_repository.this.topics) == 0
    error_message = "topics should default to empty"
  }
  assert {
    condition     = github_repository.this.auto_init == true
    error_message = "auto_init should always be true"
  }
  assert {
    condition     = length(github_repository.this.template) == 0
    error_message = "template block should be absent when source_template is null"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis) == 1
    error_message = "security_and_analysis block should be present when enable_advanced_security defaults to true"
  }
  assert {
    condition     = github_repository.this.security_and_analysis[0].advanced_security[0].status == "enabled"
    error_message = "advanced_security should be enabled"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].code_security) == 1
    error_message = "code_security sub-block should default to enabled"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning) == 1
    error_message = "secret_scanning sub-block should default to enabled"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_push_protection) == 1
    error_message = "secret_scanning_push_protection sub-block should default to enabled"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_ai_detection) == 1
    error_message = "secret_scanning_ai_detection sub-block should default to enabled"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_non_provider_patterns) == 1
    error_message = "secret_scanning_non_provider_patterns sub-block should default to enabled"
  }
  assert {
    condition     = github_branch_default.this.branch == "main"
    error_message = "default branch should always be main"
  }
  assert {
    condition     = length(github_repository_vulnerability_alerts.this) == 1
    error_message = "vulnerability alerts should be enabled by default"
  }
  assert {
    condition     = length(github_repository_dependabot_security_updates.this) == 1
    error_message = "dependabot security updates should be enabled by default"
  }
  assert {
    condition     = length(random_password.dependabot_secret) == 0
    error_message = "no random passwords should be generated when dependabot_secrets is empty"
  }
  assert {
    condition     = length(github_dependabot_secret.this) == 0
    error_message = "no dependabot secrets should be created by default"
  }
}

run "merge_fields_forced_null_when_disabled" {
  command = plan
  variables {
    allow_squash_merge = false
    allow_merge_commit = false
  }
  assert {
    condition     = github_repository.this.squash_merge_commit_title == null && github_repository.this.squash_merge_commit_message == null
    error_message = "squash merge title/message should be forced null when allow_squash_merge is false"
  }
  assert {
    condition     = github_repository.this.merge_commit_title == null && github_repository.this.merge_commit_message == null
    error_message = "merge commit title/message should be forced null when allow_merge_commit is false"
  }
}

run "security_and_analysis_disabled" {
  command = plan
  variables {
    enable_advanced_security = false
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis) == 0
    error_message = "security_and_analysis block should be entirely absent when enable_advanced_security is false, regardless of sub-toggles"
  }
}

run "security_and_analysis_independent_subflags" {
  command = plan
  variables {
    enable_advanced_security                     = true
    enable_code_security                         = false
    enable_secret_scanning_push_protection       = false
    enable_secret_scanning_non_provider_patterns = false
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].code_security) == 0
    error_message = "code_security sub-block should be absent when its flag is false"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning) == 1
    error_message = "secret_scanning sub-block should remain present when its flag is still true"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_push_protection) == 0
    error_message = "secret_scanning_push_protection sub-block should be absent when its flag is false"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_ai_detection) == 1
    error_message = "secret_scanning_ai_detection sub-block should remain present when its flag is still true"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_non_provider_patterns) == 0
    error_message = "secret_scanning_non_provider_patterns sub-block should be absent when its flag is false"
  }
}

run "source_template_dynamic_block" {
  command = plan
  variables {
    source_template = {
      owner      = "my-org"
      repository = "template-repo"
    }
  }

  assert {
    condition     = length(github_repository.this.template) == 1
    error_message = "template block should be present when source_template is set"
  }
  assert {
    condition     = github_repository.this.template[0].owner == "my-org" && github_repository.this.template[0].repository == "template-repo"
    error_message = "template owner/repository should pass through from source_template"
  }
  assert {
    condition     = github_repository.this.template[0].include_all_branches == false
    error_message = "include_all_branches should always be false"
  }
}

run "vulnerability_and_dependabot_toggles_off" {
  command = plan
  variables {
    enable_vulnerability_alerts        = false
    enable_dependabot_security_updates = false
  }
  assert {
    condition     = length(github_repository_vulnerability_alerts.this) == 0
    error_message = "vulnerability alerts resource should not be created when disabled"
  }
  assert {
    condition     = length(github_repository_dependabot_security_updates.this) == 0
    error_message = "dependabot security updates resource should not be created when disabled"
  }
}

run "dependabot_secret_explicit_value" {
  command = plan
  variables {
    dependabot_secrets = {
      MY_TOKEN = { value = "explicit-value" }
    }
  }
  assert {
    condition     = github_dependabot_secret.this["MY_TOKEN"].value == "explicit-value"
    error_message = "explicit dependabot secret value should pass through unchanged"
  }
  assert {
    condition     = length(random_password.dependabot_secret) == 0
    error_message = "no random password should be generated when a value is explicitly supplied"
  }
}

run "outputs_reflect_repository_attributes" {
  command = plan
  override_resource {
    target          = github_repository.this
    override_during = plan
    values = {
      repo_id        = 123456789
      node_id        = "R_mockid"
      full_name      = "acme-org/test-repo"
      html_url       = "https://github.com/acme-org/test-repo"
      ssh_clone_url  = "git@github.com:acme-org/test-repo.git"
      http_clone_url = "https://github.com/acme-org/test-repo.git"
    }
  }
  assert {
    condition     = output.repository_id == 123456789
    error_message = "repository_id output should reflect github_repository.this.repo_id"
  }
  assert {
    condition     = output.repository_node_id == "R_mockid"
    error_message = "repository_node_id output should reflect github_repository.this.node_id"
  }
  assert {
    condition     = output.repository_name == var.repo_name
    error_message = "repository_name output should reflect the configured repo_name"
  }
  assert {
    condition     = output.repository_full_name == "acme-org/test-repo"
    error_message = "repository_full_name output should reflect github_repository.this.full_name"
  }
  assert {
    condition     = output.repository_html_url == "https://github.com/acme-org/test-repo"
    error_message = "repository_html_url output should reflect github_repository.this.html_url"
  }
  assert {
    condition     = output.repository_ssh_clone_url == "git@github.com:acme-org/test-repo.git"
    error_message = "repository_ssh_clone_url output should reflect github_repository.this.ssh_clone_url"
  }
  assert {
    condition     = output.repository_http_clone_url == "https://github.com/acme-org/test-repo.git"
    error_message = "repository_http_clone_url output should reflect github_repository.this.http_clone_url"
  }
}

run "dependabot_secret_generated_value" {
  command = apply
  variables {
    dependabot_secrets = {
      GEN_TOKEN = {}
    }
  }
  assert {
    condition     = length(random_password.dependabot_secret) == 1
    error_message = "a random password should be generated for a dependabot secret with no explicit value"
  }
  assert {
    condition     = github_dependabot_secret.this["GEN_TOKEN"].value == random_password.dependabot_secret["GEN_TOKEN"].result
    error_message = "the dependabot secret's value should resolve to the generated random password"
  }
}

run "secret_scanning_off_disables_dependent_features" {
  command = plan
  variables {
    enable_secret_scanning = false
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis[0].secret_scanning_push_protection) == 0 && length(github_repository.this.security_and_analysis[0].secret_scanning_ai_detection) == 0 && length(github_repository.this.security_and_analysis[0].secret_scanning_non_provider_patterns) == 0
    error_message = "push protection, AI detection and non-provider patterns require secret scanning"
  }
}

run "default_branch_is_renamed" {
  command = plan
  variables {
    default_branch_name = "trunk"
  }
  assert {
    condition     = github_branch_default.this.rename == true && github_branch_default.this.branch == "trunk"
    error_message = "default branch should be renamed to default_branch_name"
  }
}

run "web_commit_signoff_toggle" {
  command = plan
  assert {
    condition     = github_repository.this.web_commit_signoff_required == false
    error_message = "web_commit_signoff_required should default to false"
  }
}

run "web_commit_signoff_enabled" {
  command = plan
  variables {
    web_commit_signoff_required = true
  }
  assert {
    condition     = github_repository.this.web_commit_signoff_required == true
    error_message = "web_commit_signoff_required should follow its variable"
  }
}
