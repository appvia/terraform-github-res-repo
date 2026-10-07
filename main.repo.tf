resource "github_repository" "this" {
  # checkov:skip=CKV_GIT_3:False positive - vulnerability alerts are a separate resource
  name                        = var.repo_name
  description                 = var.description
  visibility                  = var.visibility
  has_issues                  = var.issues_enabled
  has_projects                = var.projects_enabled
  has_wiki                    = var.wiki_enabled
  has_discussions             = var.discussions_enabled
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  squash_merge_commit_title   = var.allow_squash_merge ? var.squash_merge_commit_title : null
  squash_merge_commit_message = var.allow_squash_merge ? var.squash_merge_commit_message : null
  merge_commit_title          = var.allow_merge_commit ? var.merge_commit_title : null
  merge_commit_message        = var.allow_merge_commit ? var.merge_commit_message : null
  delete_branch_on_merge      = var.delete_branch_on_merge
  topics                      = var.topics
  auto_init                   = true
  allow_update_branch         = true
  web_commit_signoff_required = var.web_commit_signoff_required
  is_template                 = false
  dynamic "template" {
    for_each = var.source_template != null ? [var.source_template] : []
    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = false
    }
  }
  dynamic "security_and_analysis" {
    for_each = local.ghas_enabled ? ["this"] : []
    content {
      advanced_security {
        status = "enabled"
      }
      dynamic "code_security" {
        for_each = local.sa_code_security ? ["this"] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning" {
        for_each = local.sa_secret_scanning ? ["this"] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = local.sa_secret_scanning_push_protection ? ["this"] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning_ai_detection" {
        for_each = local.sa_secret_scanning_ai_detection ? ["this"] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning_non_provider_patterns" {
        for_each = local.sa_secret_scanning_non_provider_patterns ? ["this"] : []
        content {
          status = "enabled"
        }
      }
    }
  }
}

resource "github_branch_default" "this" {
  branch     = var.default_branch_name
  repository = github_repository.this.name
  # auto_init creates the repo with GitHub's default branch name, so rename it
  # rather than expecting default_branch_name to already exist.
  rename          = true
  wait_for_rename = true
}

resource "github_repository_vulnerability_alerts" "this" {
  count      = var.enable_vulnerability_alerts ? 1 : 0
  repository = github_repository.this.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "this" {
  count      = var.enable_dependabot_security_updates ? 1 : 0
  repository = github_repository.this.name
  enabled    = true
  # Security updates are only accepted once vulnerability alerts are on.
  depends_on = [github_repository_vulnerability_alerts.this]
}

resource "random_password" "dependabot_secret" {
  for_each = local.dependabot_generated_secret_names
  length   = 48
  special  = true
}

resource "github_dependabot_secret" "this" {
  for_each    = local.dependabot_secret_names
  repository  = github_repository.this.name
  secret_name = each.key
  value       = coalesce(var.dependabot_secrets[each.key].value, try(random_password.dependabot_secret[each.key].result, null))
}
