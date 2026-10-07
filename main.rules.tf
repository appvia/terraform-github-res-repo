resource "github_repository_ruleset" "branch_protection" {
  name        = "${local.repo_name_lower}-branch-protection"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }
  dynamic "bypass_actors" {
    for_each = local.ruleset_bypass_actors_by_ruleset["branch_protection"]
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  rules {
    # creation/deletion/non_fast_forward restrict those operations to
    # ruleset_bypass_actors. Direct pushes are blocked by the pull_request rule
    # below, not by "update": in GitHub's ruleset API update = true means "only
    # bypass actors may update the ref", which would also block PR merges, so it
    # must stay false.
    creation                = true
    update                  = false
    deletion                = true
    non_fast_forward        = true
    required_linear_history = local.ruleset_require_linear_history
    # Presence of this block is what forces all changes through a pull
    # request - combined with bypass_actors above for authorised direct pushes.
    pull_request {
      allowed_merge_methods             = local.ruleset_allowed_merge_methods
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = var.require_code_owner_review
      require_last_push_approval        = var.require_last_push_approval
      required_approving_review_count   = var.pull_request_reviewer_count
      required_review_thread_resolution = true
    }
    dynamic "copilot_code_review" {
      for_each = var.enable_automatic_copilot_review ? ["this"] : []
      content {
        review_draft_pull_requests = true
        review_on_push             = var.enable_automatic_copilot_review_draft_prs
      }
    }
    dynamic "required_status_checks" {
      for_each = length(var.required_status_checks) > 0 ? ["this"] : []
      content {
        strict_required_status_checks_policy = var.strict_required_status_checks
        dynamic "required_check" {
          for_each = var.required_status_checks
          content {
            context        = required_check.value.context
            integration_id = required_check.value.integration_id
          }
        }
      }
    }
  }
}

# Commit signing is enforced repo-wide rather than just on the default
# branch - split out so branch_protection can focus on the PR-merge gate.
resource "github_repository_ruleset" "commit_signing" {
  count       = var.require_signed_commits ? 1 : 0
  name        = "${local.repo_name_lower}-commit-signing"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }
  dynamic "bypass_actors" {
    for_each = local.ruleset_bypass_actors_by_ruleset["commit_signing"]
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  rules {
    required_signatures = true
  }
}

# Rulesets are scoped to a single target type, so tag signing needs its own
# resource alongside the branch one above.
resource "github_repository_ruleset" "commit_signing_tags" {
  count       = var.require_signed_tags ? 1 : 0
  name        = "${local.repo_name_lower}-commit-signing-tags"
  repository  = github_repository.this.name
  target      = "tag"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }
  dynamic "bypass_actors" {
    for_each = local.ruleset_bypass_actors_by_ruleset["commit_signing_tags"]
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  rules {
    required_signatures = true
  }
}

# Optional - the default branch can carry merge commits that don't follow
# Conventional Commits, so this excludes it and only applies elsewhere.
# commit_message_pattern is a metadata restriction rule, which GitHub only
# allows on repositories owned by a GitHub Enterprise Cloud account - hence
# also gated on enterprise_features_enabled.
resource "github_repository_ruleset" "conventional_commits" {
  count       = var.require_conventional_commits && var.enterprise_features_enabled ? 1 : 0
  name        = "${local.repo_name_lower}-conventional-commits"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = ["~DEFAULT_BRANCH"]
    }
  }
  dynamic "bypass_actors" {
    for_each = local.ruleset_bypass_actors_by_ruleset["conventional_commits"]
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  rules {
    commit_message_pattern {
      name     = "conventional-commits"
      operator = "regex"
      pattern  = var.conventional_commit_pattern
      negate   = false
    }
  }
}

# Push rulesets require GitHub Team or Enterprise Cloud - gated behind
# push_ruleset_enabled for clients on GitHub Free/Pro.
resource "github_repository_ruleset" "push_protection" {
  count       = var.push_ruleset_enabled ? 1 : 0
  name        = "${local.repo_name_lower}-push-protection"
  repository  = github_repository.this.name
  target      = "push"
  enforcement = "active"
  dynamic "bypass_actors" {
    for_each = local.ruleset_bypass_actors_by_ruleset["push_protection"]
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  rules {
    dynamic "file_path_restriction" {
      for_each = length(var.push_ruleset_file_path_restrictions) > 0 ? [1] : []
      content {
        restricted_file_paths = var.push_ruleset_file_path_restrictions
      }
    }
    dynamic "max_file_size" {
      for_each = var.push_ruleset_max_file_size_mb != null ? [1] : []
      content {
        max_file_size = var.push_ruleset_max_file_size_mb
      }
    }
    dynamic "file_extension_restriction" {
      for_each = length(var.push_ruleset_file_extension_restrictions) > 0 ? [1] : []
      content {
        restricted_file_extensions = var.push_ruleset_file_extension_restrictions
      }
    }
  }
}
