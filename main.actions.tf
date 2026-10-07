resource "github_actions_repository_permissions" "this" {
  repository           = github_repository.this.name
  enabled              = true
  sha_pinning_required = var.github_actions_sha_pinning_required
  allowed_actions      = var.allowed_actions
  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [var.allowed_actions_config] : []
    content {
      github_owned_allowed = allowed_actions_config.value.github_owned_allowed
      verified_allowed     = allowed_actions_config.value.verified_allowed
      patterns_allowed     = allowed_actions_config.value.patterns_allowed
    }
  }
}

# A null or empty claim key list means "use GitHub's default subject claim".
# include_claim_keys is ordered (it determines the layout of the sub claim), so
# the variable is a list rather than a set.
resource "github_actions_repository_oidc_subject_claim_customization_template" "this" {
  repository         = github_repository.this.name
  use_default        = local.oidc_use_default
  include_claim_keys = local.oidc_use_default ? null : var.oidc_subject_claim_keys
}

resource "github_actions_repository_access_level" "this" {
  repository   = github_repository.this.name
  access_level = var.actions_access_level
}
