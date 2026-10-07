locals {
  repo_name_lower = lower(var.repo_name)

  # Stable identifiers for the github_repository_ruleset resources below,
  # used to let ruleset_bypass_actors target specific rulesets by name.
  ruleset_names = [
    "branch_protection",
    "commit_signing",
    "commit_signing_tags",
    "conventional_commits",
    "push_protection",
  ]

  # Per-ruleset view of ruleset_bypass_actors - an actor with rulesets = null
  # applies to all of them, otherwise only to the named ones.
  ruleset_bypass_actors_by_ruleset = {
    for name in local.ruleset_names : name => [
      for a in var.ruleset_bypass_actors : a if a.rulesets == null || contains(a.rulesets, name)
    ]
  }

  ruleset_allowed_merge_methods = concat(
    var.allow_merge_commit ? ["merge"] : [],
    var.allow_squash_merge ? ["squash"] : [],
    var.allow_rebase_merge ? ["rebase"] : [],
  )

  # Merge commits are non-linear by definition, so only require linear
  # history when callers haven't opted into allowing them.
  ruleset_require_linear_history = !var.allow_merge_commit

  # GitHub Advanced Security gating. Every security_and_analysis feature needs
  # a GHAS licence, and push protection, AI detection and non-provider patterns
  # additionally need secret scanning itself - so each is gated on its parents.
  ghas_enabled                             = var.enable_advanced_security
  sa_code_security                         = local.ghas_enabled && var.enable_code_security
  sa_secret_scanning                       = local.ghas_enabled && var.enable_secret_scanning
  sa_secret_scanning_push_protection       = local.sa_secret_scanning && var.enable_secret_scanning_push_protection
  sa_secret_scanning_ai_detection          = local.sa_secret_scanning && var.enable_secret_scanning_ai_detection
  sa_secret_scanning_non_provider_patterns = local.sa_secret_scanning && var.enable_secret_scanning_non_provider_patterns

  # var.dependabot_secrets is sensitive, which would otherwise make it unusable
  # as a for_each. Secret names and whether a value was supplied are not
  # themselves sensitive, so only those are exposed here.
  dependabot_secret_names = nonsensitive(toset(keys(var.dependabot_secrets)))
  dependabot_generated_secret_names = nonsensitive(toset([
    for k, v in var.dependabot_secrets : k if v.value == null
  ]))

  oidc_use_default = var.oidc_subject_claim_keys == null || length(coalesce(var.oidc_subject_claim_keys, [])) == 0

  teams_to_create = { for k, v in var.teams : k => v if v.create }
  existing_teams  = { for k, v in var.teams : k => v if !v.create }

  teams_with_saml_sync = var.identity_provider_model == "saml_team_sync" ? {
    for k, v in var.teams : k => v if v.idp_group_name != null
  } : {}

  teams_with_emu_mapping = var.identity_provider_model == "enterprise_managed_users" ? {
    for k, v in var.teams : k => v if v.idp_group_name != null
  } : {}

  emu_external_group_id_by_name = var.identity_provider_model == "enterprise_managed_users" ? {
    for g in data.github_external_groups.this[0].external_groups : g.group_name => g.group_id
  } : {}

  team_ids_by_key = merge(
    { for k, v in github_team.this : k => v.id },
    { for k, v in data.github_team.existing : k => v.id },
  )

  team_slugs_by_key = merge(
    { for k, v in github_team.this : k => v.slug },
    { for k, v in data.github_team.existing : k => v.slug },
  )

  # Flattens var.teams[*].members (list per team) into a single map keyed by
  # "<team_key>:<username>" so it can drive a for_each on github_team_membership.
  team_members_flat = {
    for m in flatten([
      for k, v in var.teams : [
        for member in v.members : {
          id       = "${k}:${member.username}"
          team_key = k
          username = member.username
          role     = member.role
        }
      ]
    ]) : m.id => m
  }
}
