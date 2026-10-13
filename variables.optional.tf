variable "description" {
  description = "OPTIONAL: Description of the repository."
  type        = string
  default     = ""
  validation {
    condition     = length(var.description) <= 350
    error_message = "description must be 350 characters or fewer."
  }
}

variable "visibility" {
  description = "OPTIONAL: Repository visibility. One of 'private' or 'internal'. The 'internal' option requires GitHub Enterprise Cloud or GitHub Enterprise Server 2.20+."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["private", "internal"], var.visibility)
    error_message = "visibility must be one of: private, internal."
  }
}

variable "source_template" {
  description = "OPTIONAL: Details to use for a source template repository. Defaults to 'null' and will not be used."
  type = object({
    owner      = string
    repository = string
  })
  default = null
}

variable "default_branch_name" {
  description = "OPTIONAL: The name of the default, protected branch. The repository's initial branch is renamed to this if it differs. Defaults to 'main'."
  type        = string
  default     = "main"
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._/-]{0,254}$", var.default_branch_name)) && !endswith(var.default_branch_name, "/") && !endswith(var.default_branch_name, ".lock") && !strcontains(var.default_branch_name, "..")
    error_message = "default_branch_name must be a valid git branch name: start with a letter or digit, contain only letters, digits, '.', '_', '-' or '/', and not end with '/' or '.lock' or contain '..'."
  }
}

variable "issues_enabled" {
  description = "OPTIONAL: Whether or not GitHub issues are enabled on the repository. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "projects_enabled" {
  description = "OPTIONAL: Whether or not GitHub projects are enabled on the repository. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "wiki_enabled" {
  description = "OPTIONAL: Whether or not GitHub Wiki is enabled on the repository. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "discussions_enabled" {
  description = "OPTIONAL: Whether or not GitHub discussions are enabled on the repository. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "topics" {
  description = "OPTIONAL: Topics to apply to the repository. Defaults to none."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.topics) <= 20
    error_message = "topics supports at most 20 entries."
  }
  validation {
    condition     = alltrue([for t in var.topics : can(regex("^[a-z0-9][a-z0-9-]{0,49}$", t))])
    error_message = "Each topic must be lowercase alphanumeric/hyphens, starting with a letter or digit, and 50 characters or fewer."
  }
}

variable "allow_merge_commit" {
  description = "OPTIONAL: Whether or not to allow merge commits on the repo. At least one of allow_merge_commit, allow_squash_merge and allow_rebase_merge must be 'true'. Defaults to 'true'."
  type        = bool
  default     = true
  validation {
    condition     = var.allow_merge_commit || var.allow_squash_merge || var.allow_rebase_merge
    error_message = "At least one of allow_merge_commit, allow_squash_merge and allow_rebase_merge must be true."
  }
}

variable "allow_squash_merge" {
  description = "OPTIONAL: Whether or not to allow squash commits on the repo. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "OPTIONAL: Whether or not to allow merge rebase commits on the repo. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "allow_auto_merge" {
  description = "OPTIONAL: Whether or not to allow auto merge for pull requests. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "squash_merge_commit_title" {
  description = "OPTIONAL: What to use for squash merge commit title. One of 'PR_TITLE' or 'COMMIT_OR_PR_TITLE'. Defaults to 'COMMIT_OR_PR_TITLE'."
  type        = string
  default     = "COMMIT_OR_PR_TITLE"
  validation {
    condition     = contains(["PR_TITLE", "COMMIT_OR_PR_TITLE"], var.squash_merge_commit_title)
    error_message = "ERROR: var.squash_merge_commit_title must be one of: PR_TITLE, COMMIT_OR_PR_TITLE."
  }
}

variable "squash_merge_commit_message" {
  description = "OPTIONAL: What to use for squash merge commit message. One of 'PR_BODY', 'COMMIT_MESSAGES', or 'BLANK'. Defaults to 'COMMIT_MESSAGES' - GitHub only allows squash_merge_commit_title = 'COMMIT_OR_PR_TITLE' paired with squash_merge_commit_message = 'COMMIT_MESSAGES'."
  type        = string
  default     = "COMMIT_MESSAGES"
  validation {
    condition     = contains(["PR_BODY", "COMMIT_MESSAGES", "BLANK"], var.squash_merge_commit_message)
    error_message = "ERROR: var.squash_merge_commit_message must be one of: PR_BODY, COMMIT_MESSAGES, BLANK."
  }
  validation {
    condition = (
      (var.squash_merge_commit_title == "PR_TITLE" && contains(["PR_BODY", "BLANK", "COMMIT_MESSAGES"], var.squash_merge_commit_message)) ||
      (var.squash_merge_commit_title == "COMMIT_OR_PR_TITLE" && var.squash_merge_commit_message == "COMMIT_MESSAGES")
    )
    error_message = "ERROR: invalid squash_merge_commit_title/squash_merge_commit_message combination. GitHub only accepts: PR_TITLE+PR_BODY, PR_TITLE+BLANK, PR_TITLE+COMMIT_MESSAGES, COMMIT_OR_PR_TITLE+COMMIT_MESSAGES."
  }
}

variable "merge_commit_title" {
  description = "OPTIONAL: What to use for merge commit title. One of 'PR_TITLE' or 'MERGE_MESSAGE'. Defaults to 'MERGE_MESSAGE'."
  type        = string
  default     = "MERGE_MESSAGE"
  validation {
    condition     = contains(["PR_TITLE", "MERGE_MESSAGE"], var.merge_commit_title)
    error_message = "ERROR: var.merge_commit_title must be one of: PR_TITLE, MERGE_MESSAGE."
  }
}

variable "merge_commit_message" {
  description = "OPTIONAL: What to use for merge commit message. One of 'PR_BODY', 'PR_TITLE', or 'BLANK'. Defaults to 'PR_TITLE' - GitHub only allows merge_commit_title = 'MERGE_MESSAGE' paired with merge_commit_message = 'PR_TITLE'."
  type        = string
  default     = "PR_TITLE"
  validation {
    condition     = contains(["PR_BODY", "PR_TITLE", "BLANK"], var.merge_commit_message)
    error_message = "ERROR: var.merge_commit_message must be one of: PR_BODY, PR_TITLE, BLANK."
  }
  validation {
    condition = (
      (var.merge_commit_title == "PR_TITLE" && contains(["PR_BODY", "BLANK"], var.merge_commit_message)) ||
      (var.merge_commit_title == "MERGE_MESSAGE" && var.merge_commit_message == "PR_TITLE")
    )
    error_message = "ERROR: invalid merge_commit_title/merge_commit_message combination. GitHub only accepts: PR_TITLE+PR_BODY, PR_TITLE+BLANK, MERGE_MESSAGE+PR_TITLE."
  }
}

variable "web_commit_signoff_required" {
  description = "OPTIONAL: Whether contributors must sign off on commits made through GitHub's web interface. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "delete_branch_on_merge" {
  description = "OPTIONAL: Whether to delete source branch on merge. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_advanced_security" {
  description = "OPTIONAL: Whether to enable GitHub Advanced Security for private/internal repositories. Requires a GHAS license. This is the master switch: every enable_code_security and enable_secret_scanning* option below is ignored when it is 'false'. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_secret_scanning" {
  description = "OPTIONAL: Whether to enable secret scanning. Only takes effect when advanced security is enabled. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_secret_scanning_push_protection" {
  description = "OPTIONAL: Whether to enable secret scanning push protection. Only takes effect when enable_advanced_security and enable_secret_scanning are both 'true'. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_code_security" {
  description = "OPTIONAL: Whether to enable GitHub Code Security, the unified security configuration covering Dependabot, secret scanning and code scanning. Only takes effect when enable_advanced_security is 'true'. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_secret_scanning_ai_detection" {
  description = "OPTIONAL: Whether to enable secret scanning detection for AI provider credentials (e.g. OpenAI, Anthropic API keys). Only takes effect when enable_advanced_security and enable_secret_scanning are both 'true'. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_secret_scanning_non_provider_patterns" {
  description = "OPTIONAL: Whether to enable secret scanning for generic, non-provider-specific secret patterns. Broader recall than provider-specific patterns, but can be noisier. Only takes effect when enable_advanced_security and enable_secret_scanning are both 'true'. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_vulnerability_alerts" {
  description = "OPTIONAL: Whether to enable vulnerability alerts. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_dependabot_security_updates" {
  description = "OPTIONAL: Whether to enable Dependabot automated security fixes (pull requests that bump a dependency when a vulnerability alert fires) for the repository. Requires enable_vulnerability_alerts = true. Defaults to 'true'."
  type        = bool
  default     = true
  validation {
    condition     = !var.enable_dependabot_security_updates || var.enable_vulnerability_alerts
    error_message = "enable_dependabot_security_updates requires enable_vulnerability_alerts to be true."
  }
}

variable "issue_labels" {
  description = "OPTIONAL: Issue labels to create on the repository, keyed by label name. Color is a 6 character hex code without the leading '#'."
  type = map(object({
    color       = string
    description = optional(string, "")
  }))
  default = {
    "terraform-drift" = {
      color       = "FBCA04"
      description = "Live infrastructure has drifted from the Terraform configuration"
    }
    "terraform-bug" = {
      color       = "D93F0B"
      description = "Something is broken in the Terraform configuration or module"
    }
    "workflow-bug" = {
      color       = "B60205"
      description = "Something is broken in a GitHub Actions workflow"
    }
    "security" = {
      color       = "EE0701"
      description = "Security-related issue, e.g. secret scanning, vulnerability alerts, or Dependabot"
    }
  }
  validation {
    condition     = alltrue([for k, v in var.issue_labels : can(regex("^[0-9A-Fa-f]{6}$", v.color))])
    error_message = "Each label's color must be a 6 character hex code without the leading '#'."
  }
  validation {
    condition     = alltrue([for k, v in var.issue_labels : length(v.description) <= 100])
    error_message = "Each label's description must be 100 characters or fewer."
  }
}

variable "dependabot_secrets" {
  description = "OPTIONAL: Dependabot secrets to create for the repository, keyed by secret name. Set value to a specific value, or omit it to generate a random value instead. Values are held in Terraform state, so treat state as sensitive. Defaults to an empty map."
  type = map(object({
    value = optional(string)
  }))
  default   = {}
  sensitive = true
  validation {
    condition     = alltrue([for k, v in var.dependabot_secrets : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", k)) && !startswith(upper(k), "GITHUB_")])
    error_message = "Each secret name must be alphanumeric/underscore, not start with a digit, and not start with the reserved 'GITHUB_' prefix."
  }
}

variable "ruleset_bypass_actors" {
  description = <<-EOT
    OPTIONAL: Actors allowed to bypass the repo's rulesets.
    actor_type one of: RepositoryRole, Team, Integration, OrganizationAdmin,
    DeployKey, EnterpriseOwner, User. actor_id is required for RepositoryRole
    (2 maintain, 4 write, 5 admin), Team, Integration (App ID) and User
    (numeric user ID); see the github_repository_ruleset docs.
    rulesets optionally restricts which rulesets the actor applies to - one
    or more of: branch_protection, commit_signing, commit_signing_tags,
    conventional_commits, push_protection. Leave unset to bypass all of them.
  EOT
  type = list(object({
    actor_id    = optional(number)
    actor_type  = string
    bypass_mode = optional(string, "always")
    rulesets    = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for a in var.ruleset_bypass_actors : contains(
        ["RepositoryRole", "Team", "Integration", "OrganizationAdmin", "DeployKey", "EnterpriseOwner", "User"],
        a.actor_type
      )
    ])
    error_message = "ERROR: Each bypass actor's actor_type must be one of: RepositoryRole, Team, Integration, OrganizationAdmin, DeployKey, EnterpriseOwner, User."
  }
  validation {
    condition     = alltrue([for a in var.ruleset_bypass_actors : contains(["always", "pull_request", "exempt"], a.bypass_mode)])
    error_message = "ERROR: Each bypass actor's bypass_mode must be one of: always, pull_request, exempt."
  }
  validation {
    condition = alltrue([
      for a in var.ruleset_bypass_actors : a.rulesets == null || alltrue([
        for r in a.rulesets : contains(local.ruleset_names, r)
      ])
    ])
    error_message = "ERROR: Each bypass actor's rulesets must only contain: ${join(", ", local.ruleset_names)}."
  }
  validation {
    condition = alltrue([
      for a in var.ruleset_bypass_actors : !contains(["RepositoryRole", "Team", "Integration", "User"], a.actor_type) || a.actor_id != null
    ])
    error_message = "ERROR: actor_id is required when a bypass actor's actor_type is RepositoryRole (2 maintain, 4 write, 5 admin), Team (team ID), Integration (GitHub App ID) or User (numeric user ID)."
  }
}

variable "push_ruleset_enabled" {
  description = "OPTIONAL: Whether to create the push ruleset (file path/size/extension restrictions). Requires GitHub Team or Enterprise Cloud. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "require_code_owner_review" {
  description = "OPTIONAL: Whether pull requests to the default branch need approval from a code owner. Only enforced for paths covered by a CODEOWNERS file - with no CODEOWNERS file it has no effect. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "require_last_push_approval" {
  description = "OPTIONAL: Whether the most recent pusher to a pull request must have their changes approved by someone else. Set to 'false' for solo-maintained repositories, where nobody else can approve. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "strict_required_status_checks" {
  description = "OPTIONAL: Whether branches must be up to date with the default branch before merging (GitHub's 'require branches to be up to date'). Defaults to 'false'."
  type        = bool
  default     = false
}

variable "enable_automatic_copilot_review" {
  description = "OPTIONAL: Whether or not to enable automatic copilot review of pull requests. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "enable_automatic_copilot_review_draft_prs" {
  description = "OPTIONAL: Whether or not to enable automatic copilot review of draft pull requests. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "require_signed_commits" {
  description = "OPTIONAL: Whether commits must use git cryptographic signatures. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "require_signed_tags" {
  description = "OPTIONAL: Whether tags must use git cryptographic signatures. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "require_conventional_commits" {
  description = "OPTIONAL: Whether to enforce conventional commit messages on every branch except the default branch (which may carry non-conforming merge commits). Defaults to 'true'. Uses the commit_message_pattern rule, which GitHub restricts to repositories owned by a GitHub Enterprise Cloud account - has no effect unless enterprise_features_enabled is also 'true'."
  type        = bool
  default     = true
}

variable "conventional_commit_pattern" {
  description = "OPTIONAL: The pattern for enforcing conventional commits in the push ruleset rule."
  type        = string
  default     = "^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\(.+\\))?!?: .+$"
}

variable "pull_request_reviewer_count" {
  description = "OPTIONAL: The number of reviewers required on pull requests. Must be >= 0. Defaults to 1."
  type        = number
  default     = 1
  validation {
    condition     = var.pull_request_reviewer_count >= 0
    error_message = "ERROR: The variable var.pull_request_reviewer_count must be >= 0."
  }
}

variable "push_ruleset_file_path_restrictions" {
  description = "OPTIONAL: File path patterns blocked from being pushed, when push_ruleset_enabled = true. Defaults to none."
  type        = list(string)
  default     = []
}

variable "push_ruleset_max_file_size_mb" {
  description = "OPTIONAL: Maximum file size (MB, 1-100) allowed in a push, when push_ruleset_enabled = true. Defaults to 'null' (no limit)."
  type        = number
  default     = null
  validation {
    condition     = var.push_ruleset_max_file_size_mb == null || (var.push_ruleset_max_file_size_mb >= 1 && var.push_ruleset_max_file_size_mb <= 100)
    error_message = "ERROR: push_ruleset_max_file_size_mb must be between 1 and 100."
  }
}

variable "push_ruleset_file_extension_restrictions" {
  description = "OPTIONAL: File extensions blocked from being pushed, when push_ruleset_enabled = true. Defaults to none."
  type        = list(string)
  default     = []
}

variable "enterprise_features_enabled" {
  description = "OPTIONAL: Whether enterprise licensing is enabled. This gates relevant features that are not available without this. Defaults to 'true'."
  type        = bool
  default     = true
}

variable "oidc_subject_claim_keys" {
  description = "OPTIONAL: Ordered claim keys used to build the OIDC subject claim in federated credentials. Order is significant. Set to null or [] to use GitHub's default subject claim. Defaults to [\"repo\", \"environment\", \"job_workflow_ref\"]."
  type        = list(string)
  default     = ["repo", "environment", "job_workflow_ref"]
  validation {
    condition     = var.oidc_subject_claim_keys == null || alltrue([for k in var.oidc_subject_claim_keys : can(regex("^[A-Za-z0-9_]+$", k))])
    error_message = "Each claim key must contain only alphanumeric characters and underscores."
  }
  validation {
    condition     = var.oidc_subject_claim_keys == null || length(var.oidc_subject_claim_keys) == length(distinct(var.oidc_subject_claim_keys))
    error_message = "oidc_subject_claim_keys must not contain duplicates."
  }
}

variable "allowed_actions" {
  description = "OPTIONAL: Which GitHub Actions may run in this repository. One of 'all', 'local_only' or 'selected'. 'selected' requires allowed_actions_config. Defaults to 'all'; restrict this if workflows do not need third-party actions."
  type        = string
  default     = "all"
  validation {
    condition     = contains(["all", "local_only", "selected"], var.allowed_actions)
    error_message = "allowed_actions must be one of: all, local_only, selected."
  }
}

variable "allowed_actions_config" {
  description = "OPTIONAL: Allow-list used when allowed_actions = 'selected'. Defaults to 'null'."
  type = object({
    github_owned_allowed = bool
    verified_allowed     = optional(bool, false)
    patterns_allowed     = optional(set(string), [])
  })
  default = null
  validation {
    condition     = var.allowed_actions != "selected" || var.allowed_actions_config != null
    error_message = "allowed_actions_config must be set when allowed_actions = \"selected\"."
  }
  validation {
    condition     = var.allowed_actions == "selected" || var.allowed_actions_config == null
    error_message = "allowed_actions_config can only be set when allowed_actions = \"selected\"."
  }
}

variable "actions_access_level" {
  description = "OPTIONAL: Whether this repository's actions/reusable workflows may be used by others. Defaults to 'none'."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "user", "organization", "enterprise"], var.actions_access_level)
    error_message = "ERROR: actions_access_level must be one of: none, user, organization, enterprise."
  }
}

variable "identity_provider_model" {
  description = <<-EOT
    OPTIONAL: How GitHub team membership is synced with the identity provider
    (Entra ID), for teams that opt in via idp_group_name on var.teams. One of:

    - saml_team_sync: GHEC SAML SSO + Team Sync (needs enterprise owner
      one-time setup + Graph consent). Links via github_team_sync_group_mapping
      using the raw Entra group object ID (idp_group_id).
    - enterprise_managed_users: GitHub EMU + SCIM (needs SCIM provisioning
      against Entra already configured). Links via github_emu_group_mapping,
      resolving idp_group_name against GitHub's SCIM external groups -
      idp_group_id is not used.
    - standalone: no native GitHub<->IdP linkage. idp_group_name/idp_group_id
      must not be set; membership can be managed via each team's `members`.

    Defaults to 'standalone'.
  EOT
  type        = string
  default     = "standalone"
  validation {
    condition     = contains(["saml_team_sync", "enterprise_managed_users", "standalone"], var.identity_provider_model)
    error_message = "identity_provider_model must be one of: saml_team_sync, enterprise_managed_users, standalone."
  }
}

variable "teams" {
  description = <<-EOT
    OPTIONAL: Teams to attach to the repository, keyed by the team's slug
    (when referencing an existing team) or desired slug (when creating one).
    Defaults to {}.

    - permission: one of pull, triage, push, maintain, admin, or an existing
      custom repository role's name (not validated here - this module is
      repo-scoped and does not create org-level custom roles).
    - create: if true, creates the team (github_team); if false, looks up an
      existing team by slug and only attaches the permission.
    - name/description/privacy/parent_team_id: used only when create = true.
      parent_team_id is the numeric ID or slug of an existing team (not one
      created in the same call).
    - idp_group_id/idp_group_name/idp_group_description: links the team to an
      already-existing Entra ID group. idp_group_name is required under
      saml_team_sync or enterprise_managed_users; idp_group_id (the raw Entra
      object ID) is additionally required under saml_team_sync, and ignored
      under enterprise_managed_users (resolved from idp_group_name instead).
    - members: optional list of { username, role } managed via
      github_team_membership. Only valid when idp_group_name is null - once
      IdP-linked, GitHub requires membership changes via the identity
      provider, not Terraform.
  EOT
  type = map(object({
    permission            = string
    create                = optional(bool, false)
    name                  = optional(string)
    description           = optional(string)
    privacy               = optional(string, "closed")
    parent_team_id        = optional(string)
    idp_group_id          = optional(string)
    idp_group_name        = optional(string)
    idp_group_description = optional(string)
    members = optional(list(object({
      username = string
      role     = optional(string, "member")
    })), [])
  }))
  default = {}
  validation {
    condition     = alltrue([for k, v in var.teams : trimspace(v.permission) != ""])
    error_message = "Each team's permission must be set - one of pull, triage, push, maintain, admin, or the name of an existing custom repository role."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : contains(["secret", "closed"], v.privacy)])
    error_message = "Each team's privacy must be one of: secret, closed."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : !v.create || (v.name != null && v.name != "")])
    error_message = "Each team with create = true must set name."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : !(v.parent_team_id != null && v.idp_group_name != null)])
    error_message = "A team cannot set both parent_team_id and idp_group_name - GitHub forbids nesting for IdP-synced teams."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : v.idp_group_id == null || v.idp_group_name != null])
    error_message = "idp_group_name is required on any team entry that sets idp_group_id."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : var.identity_provider_model != "saml_team_sync" || v.idp_group_name == null || v.idp_group_id != null])
    error_message = "idp_group_id is required on any team entry that sets idp_group_name when identity_provider_model = saml_team_sync."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : v.idp_group_name == null || var.identity_provider_model != "standalone"])
    error_message = "idp_group_name was set on one or more teams but identity_provider_model is \"standalone\" (no native GitHub<->IdP team linkage). Set identity_provider_model to saml_team_sync or enterprise_managed_users, or remove idp_group_name and use members instead."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : v.idp_group_name == null || length(v.members) == 0])
    error_message = "A team cannot set both idp_group_name and members - once a team is connected to an IdP group, membership changes must happen through the identity provider, not Terraform."
  }
  validation {
    condition     = alltrue([for k, v in var.teams : alltrue([for m in v.members : contains(["member", "maintainer"], m.role)])])
    error_message = "Each member's role must be one of: member, maintainer."
  }
}

variable "required_status_checks" {
  description = "OPTIONAL: Status checks that must pass before merging. Each entry is { context, integration_id }. Defaults to a single check named 'terraform-pull-request' - the aggregator job gating PRs on the terraform test pipeline. NOTE: the default is a required check, so PRs cannot merge until a workflow reporting that context exists; set to [] if the repository does not use it."
  type = list(object({
    context        = string
    integration_id = optional(number)
  }))
  default = [{ context = "terraform-pull-request" }]
}

variable "github_actions_sha_pinning_required" {
  description = "OPTIONAL: Whether GitHub actions require SHA pinning for action references. Defaults to 'true' for enhanced security."
  type        = bool
  default     = true
}
