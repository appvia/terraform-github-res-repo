<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://raw.githubusercontent.com/appvia/terraform-github-res-repo/refs/heads/main/docs/banner.jpg" alt="Appvia Banner"/></a><br/><p align="right"> </a> <a href="https://registry.terraform.io/modules/appvia/terraform-github-res-repo/azurerm/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a> <a href="https://github.com/appvia/terraform-github-res-repo/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-github-res-repo.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-github-res-repo/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-github-res-repo.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: Placeholders (terraform-github-res-repo, terraform-github-res-repo) are managed by scripts/init-from-template.sh ******
-->

![Github Actions](https://github.com/appvia/terraform-github-res-repo/actions/workflows/terraform.yml/badge.svg)

# Terraform GitHub Res Repo

## Description
This module creates a new GitHub repository, aligned with best practices. This module is aimed exclusively at the "singleton" components of a typical Terraform deployment - i.e. the components that are deployed once, regardless of the number of environments configured (dev, staging, production etc). A separate module will take care of the per-environment aspects of GitHub configuration.

### Resources created

- **Repository** - private or internal repository (optionally from a template) with a configurable default branch and merge settings.
- **Security** - vulnerability alerts, Dependabot security updates, GitHub Advanced Security and secret scanning, each individually toggleable.
- **Dependabot secrets** - supplied or randomly generated.
- **Rulesets** - default branch protection (pull requests, code owner review, status checks, linear history), plus optional signed commits/tags, conventional commits and push restrictions, with configurable bypass actors.
- **Teams** - new or existing teams with repository permissions, members and optional Entra ID group sync.
- **Actions** - repository permissions with SHA pinning, access level and optional OIDC subject claim customisation.
- **Issue labels** - sensible defaults, overridable.

The module also exposes outputs for the repository (ID, node ID, name, full name, URLs and clone URLs) and for the IDs and slugs of the attached teams.

Many resources have configurable settings exposed with sane defaults, but can be overriden where necessary.

## Usage

The only required input is `repo_name`. Everything else has a secure default.

```hcl
provider "github" {}

module "repo" {
  source = "github.com/appvia/terraform-github-res-repo?ref=v0.0.1"

  repo_name   = "my-service"
  description = "My service repository."
  visibility  = "private"
  topics      = ["terraform", "platform"]

  # Squash-only merging, with one approving review.
  allow_merge_commit          = false
  allow_rebase_merge          = false
  pull_request_reviewer_count = 1

  # Require signed commits and tags.
  require_signed_commits = true
  require_signed_tags    = true

  # Gate merges on the CI aggregator job.
  required_status_checks = [{ context = "terraform-pull-request" }]

  # Let organisation admins bypass branch protection only.
  ruleset_bypass_actors = [
    {
      actor_id    = 1
      actor_type  = "OrganizationAdmin"
      bypass_mode = "pull_request"
      rulesets    = ["branch_protection"]
    }
  ]

  # Attach one new team and one existing team.
  teams = {
    platform = {
      permission = "admin"
      create     = true
      name       = "platform"
      members    = [{ username = "octocat", role = "maintainer" }]
    }
    readers = {
      permission = "pull"
      create     = false
    }
  }

  issue_labels = {
    "terraform-drift" = {
      color      = "FBCA04"
      description = "Live infrastructure has drifted from the Terraform configuration"
    }
  }
}

output "repo_url" {
  value = module.repo.repository_html_url
}
```

### Non-secure defaults

Defaults are secure unless listed here. Each is a deliberate trade-off; override it where the justification does not apply.

| Default | Why it is not the most secure setting |
| --- | --- |
| `allowed_actions = "all"` | Restricting to `local_only` or `selected` would mean maintaining allow-lists and, because OIDC subject claims include `job_workflow_ref`, re-issuing OIDC federated credentials whenever central workflow templates are updated. Mitigated by `github_actions_sha_pinning_required = true` (default). |
| `strict_required_status_checks = false` | Branches need not be up to date with the default branch before merging. Strict mode forces a rebase and re-run of checks on every merge, which hurts merge throughput; required checks and reviews remain the gate, and `allow_auto_merge` still honours every rule. |
| `allow_auto_merge = true` | Convenience and throughput. Auto-merge only completes once all ruleset requirements (reviews, required checks) are met. |
| `required_approving_review_count = 1` | A single reviewer is the baseline; raise `pull_request_reviewer_count` for higher-assurance repositories. |
| `require_conventional_commits` has no effect unless `enterprise_features_enabled = true` | GitHub only permits commit message rules on Enterprise Cloud owned repositories. |
| `push_ruleset_enabled = false` | Push rulesets (file path, size and extension restrictions) need GitHub Team or Enterprise Cloud, so they are opt-in. |

### Notes

- Some features depend on your GitHub plan: `enable_advanced_security` needs a GHAS licence, `push_ruleset_enabled` needs Team or Enterprise Cloud, and `require_conventional_commits` also needs `enterprise_features_enabled = true`.
- `enable_advanced_security` is the master switch for all code security and secret scanning options; they are ignored when it is `false`. Disable it (and `enable_code_security`) on organisations without GHAS licensing.
- `required_status_checks` defaults to a required `terraform-pull-request` check. PRs cannot merge until a workflow reports that context - set it to `[]` if the repository does not use it.
- On solo-maintained repositories set `require_last_push_approval = false`, otherwise nobody else can approve the last push.
- Teams linked to an identity provider (`idp_group_name`) are governed by `identity_provider_model` (`standalone`, `saml_team_sync` or `enterprise_managed_users`). Membership of linked teams must be managed in the identity provider, not via `members`.
- The `github` provider must be authenticated with permissions to manage repositories, rulesets, teams and Actions settings in the target organisation.

## Examples

See the [examples](./examples) directory for working usage examples.

- [Basic](./examples/basic) - A private repository with default security settings and rulesets, one newly created `platform` team with `admin` access, and an existing `readers` team with `pull` access.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.13 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.13 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [github_actions_repository_access_level.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_repository_access_level) | resource |
| [github_actions_repository_oidc_subject_claim_customization_template.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_repository_oidc_subject_claim_customization_template) | resource |
| [github_actions_repository_permissions.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_repository_permissions) | resource |
| [github_branch_default.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_dependabot_secret.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/dependabot_secret) | resource |
| [github_emu_group_mapping.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/emu_group_mapping) | resource |
| [github_issue_label.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/issue_label) | resource |
| [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_dependabot_security_updates.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_dependabot_security_updates) | resource |
| [github_repository_ruleset.branch_protection](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_ruleset.commit_signing](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_ruleset.commit_signing_tags](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_ruleset.conventional_commits](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_ruleset.push_protection](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_vulnerability_alerts.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_vulnerability_alerts) | resource |
| [github_team.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team) | resource |
| [github_team_membership.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_membership) | resource |
| [github_team_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_repository) | resource |
| [github_team_sync_group_mapping.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_sync_group_mapping) | resource |
| [random_password.dependabot_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | REQUIRED: Name of the GitHub repository to create. | `string` | n/a | yes |
| <a name="input_actions_access_level"></a> [actions\_access\_level](#input\_actions\_access\_level) | OPTIONAL: Whether this repository's actions/reusable workflows may be used by others. Defaults to 'none'. | `string` | `"none"` | no |
| <a name="input_allow_auto_merge"></a> [allow\_auto\_merge](#input\_allow\_auto\_merge) | OPTIONAL: Whether or not to allow auto merge for pull requests. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_allow_merge_commit"></a> [allow\_merge\_commit](#input\_allow\_merge\_commit) | OPTIONAL: Whether or not to allow merge commits on the repo. At least one of allow\_merge\_commit, allow\_squash\_merge and allow\_rebase\_merge must be 'true'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_allow_rebase_merge"></a> [allow\_rebase\_merge](#input\_allow\_rebase\_merge) | OPTIONAL: Whether or not to allow merge rebase commits on the repo. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_allow_squash_merge"></a> [allow\_squash\_merge](#input\_allow\_squash\_merge) | OPTIONAL: Whether or not to allow squash commits on the repo. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_allowed_actions"></a> [allowed\_actions](#input\_allowed\_actions) | OPTIONAL: Which GitHub Actions may run in this repository. One of 'all', 'local\_only' or 'selected'. 'selected' requires allowed\_actions\_config. Defaults to 'all'; restrict this if workflows do not need third-party actions. | `string` | `"all"` | no |
| <a name="input_allowed_actions_config"></a> [allowed\_actions\_config](#input\_allowed\_actions\_config) | OPTIONAL: Allow-list used when allowed\_actions = 'selected'. Defaults to 'null'. | <pre>object({<br/>    github_owned_allowed = bool<br/>    verified_allowed     = optional(bool, false)<br/>    patterns_allowed     = optional(set(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_conventional_commit_pattern"></a> [conventional\_commit\_pattern](#input\_conventional\_commit\_pattern) | OPTIONAL: The pattern for enforcing conventional commits in the push ruleset rule. | `string` | `"^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\(.+\\))?!?: .+$"` | no |
| <a name="input_default_branch_name"></a> [default\_branch\_name](#input\_default\_branch\_name) | OPTIONAL: The name of the default, protected branch. The repository's initial branch is renamed to this if it differs. Defaults to 'main'. | `string` | `"main"` | no |
| <a name="input_delete_branch_on_merge"></a> [delete\_branch\_on\_merge](#input\_delete\_branch\_on\_merge) | OPTIONAL: Whether to delete source branch on merge. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_dependabot_secrets"></a> [dependabot\_secrets](#input\_dependabot\_secrets) | OPTIONAL: Dependabot secrets to create for the repository, keyed by secret name. Set value to a specific value, or omit it to generate a random value instead. Values are held in Terraform state, so treat state as sensitive. Defaults to an empty map. | <pre>map(object({<br/>    value = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | OPTIONAL: Description of the repository. | `string` | `""` | no |
| <a name="input_discussions_enabled"></a> [discussions\_enabled](#input\_discussions\_enabled) | OPTIONAL: Whether or not GitHub discussions are enabled on the repository. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_enable_advanced_security"></a> [enable\_advanced\_security](#input\_enable\_advanced\_security) | OPTIONAL: Whether to enable GitHub Advanced Security for private/internal repositories. Requires a GHAS license. This is the master switch: every enable\_code\_security and enable\_secret\_scanning* option below is ignored when it is 'false'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_automatic_copilot_review"></a> [enable\_automatic\_copilot\_review](#input\_enable\_automatic\_copilot\_review) | OPTIONAL: Whether or not to enable automatic copilot review of pull requests. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_automatic_copilot_review_draft_prs"></a> [enable\_automatic\_copilot\_review\_draft\_prs](#input\_enable\_automatic\_copilot\_review\_draft\_prs) | OPTIONAL: Whether or not to enable automatic copilot review of draft pull requests. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_enable_code_security"></a> [enable\_code\_security](#input\_enable\_code\_security) | OPTIONAL: Whether to enable GitHub Code Security, the unified security configuration covering Dependabot, secret scanning and code scanning. Only takes effect when enable\_advanced\_security is 'true'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_dependabot_security_updates"></a> [enable\_dependabot\_security\_updates](#input\_enable\_dependabot\_security\_updates) | OPTIONAL: Whether to enable Dependabot automated security fixes (pull requests that bump a dependency when a vulnerability alert fires) for the repository. Requires enable\_vulnerability\_alerts = true. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_secret_scanning"></a> [enable\_secret\_scanning](#input\_enable\_secret\_scanning) | OPTIONAL: Whether to enable secret scanning. Only takes effect when advanced security is enabled. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_secret_scanning_ai_detection"></a> [enable\_secret\_scanning\_ai\_detection](#input\_enable\_secret\_scanning\_ai\_detection) | OPTIONAL: Whether to enable secret scanning detection for AI provider credentials (e.g. OpenAI, Anthropic API keys). Only takes effect when enable\_advanced\_security and enable\_secret\_scanning are both 'true'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_secret_scanning_non_provider_patterns"></a> [enable\_secret\_scanning\_non\_provider\_patterns](#input\_enable\_secret\_scanning\_non\_provider\_patterns) | OPTIONAL: Whether to enable secret scanning for generic, non-provider-specific secret patterns. Broader recall than provider-specific patterns, but can be noisier. Only takes effect when enable\_advanced\_security and enable\_secret\_scanning are both 'true'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_secret_scanning_push_protection"></a> [enable\_secret\_scanning\_push\_protection](#input\_enable\_secret\_scanning\_push\_protection) | OPTIONAL: Whether to enable secret scanning push protection. Only takes effect when enable\_advanced\_security and enable\_secret\_scanning are both 'true'. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enable_vulnerability_alerts"></a> [enable\_vulnerability\_alerts](#input\_enable\_vulnerability\_alerts) | OPTIONAL: Whether to enable vulnerability alerts. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_enterprise_features_enabled"></a> [enterprise\_features\_enabled](#input\_enterprise\_features\_enabled) | OPTIONAL: Whether enterprise licensing is enabled. This gates relevant features that are not available without this. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_github_actions_sha_pinning_required"></a> [github\_actions\_sha\_pinning\_required](#input\_github\_actions\_sha\_pinning\_required) | OPTIONAL: Whether GitHub actions require SHA pinning for action references. Defaults to 'true' for enhanced security. | `bool` | `true` | no |
| <a name="input_identity_provider_model"></a> [identity\_provider\_model](#input\_identity\_provider\_model) | OPTIONAL: How GitHub team membership is synced with the identity provider<br/>(Entra ID), for teams that opt in via idp\_group\_name on var.teams. One of:<br/><br/>- saml\_team\_sync: GHEC SAML SSO + Team Sync (needs enterprise owner<br/>  one-time setup + Graph consent). Links via github\_team\_sync\_group\_mapping<br/>  using the raw Entra group object ID (idp\_group\_id).<br/>- enterprise\_managed\_users: GitHub EMU + SCIM (needs SCIM provisioning<br/>  against Entra already configured). Links via github\_emu\_group\_mapping,<br/>  resolving idp\_group\_name against GitHub's SCIM external groups -<br/>  idp\_group\_id is not used.<br/>- standalone: no native GitHub<->IdP linkage. idp\_group\_name/idp\_group\_id<br/>  must not be set; membership can be managed via each team's `members`.<br/><br/>Defaults to 'standalone'. | `string` | `"standalone"` | no |
| <a name="input_issue_labels"></a> [issue\_labels](#input\_issue\_labels) | OPTIONAL: Issue labels to create on the repository, keyed by label name. Color is a 6 character hex code without the leading '#'. | <pre>map(object({<br/>    color       = string<br/>    description = optional(string, "")<br/>  }))</pre> | <pre>{<br/>  "security": {<br/>    "color": "EE0701",<br/>    "description": "Security-related issue, e.g. secret scanning, vulnerability alerts, or Dependabot"<br/>  },<br/>  "terraform-bug": {<br/>    "color": "D93F0B",<br/>    "description": "Something is broken in the Terraform configuration or module"<br/>  },<br/>  "terraform-drift": {<br/>    "color": "FBCA04",<br/>    "description": "Live infrastructure has drifted from the Terraform configuration"<br/>  },<br/>  "workflow-bug": {<br/>    "color": "B60205",<br/>    "description": "Something is broken in a GitHub Actions workflow"<br/>  }<br/>}</pre> | no |
| <a name="input_issues_enabled"></a> [issues\_enabled](#input\_issues\_enabled) | OPTIONAL: Whether or not GitHub issues are enabled on the repository. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_merge_commit_message"></a> [merge\_commit\_message](#input\_merge\_commit\_message) | OPTIONAL: What to use for merge commit message. One of 'PR\_BODY', 'PR\_TITLE', or 'BLANK'. Defaults to 'PR\_TITLE' - GitHub only allows merge\_commit\_title = 'MERGE\_MESSAGE' paired with merge\_commit\_message = 'PR\_TITLE'. | `string` | `"PR_TITLE"` | no |
| <a name="input_merge_commit_title"></a> [merge\_commit\_title](#input\_merge\_commit\_title) | OPTIONAL: What to use for merge commit title. One of 'PR\_TITLE' or 'MERGE\_MESSAGE'. Defaults to 'MERGE\_MESSAGE'. | `string` | `"MERGE_MESSAGE"` | no |
| <a name="input_oidc_subject_claim_keys"></a> [oidc\_subject\_claim\_keys](#input\_oidc\_subject\_claim\_keys) | OPTIONAL: Ordered claim keys used to build the OIDC subject claim in federated credentials. Order is significant. Set to null or [] to use GitHub's default subject claim. Defaults to ["repository", "repository\_id", "repository\_owner\_id", "job\_workflow\_ref", "ref", "environment"]. | `list(string)` | <pre>[<br/>  "repository",<br/>  "repository_id",<br/>  "repository_owner_id",<br/>  "job_workflow_ref",<br/>  "ref",<br/>  "environment"<br/>]</pre> | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | OPTIONAL: Whether or not GitHub projects are enabled on the repository. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_pull_request_reviewer_count"></a> [pull\_request\_reviewer\_count](#input\_pull\_request\_reviewer\_count) | OPTIONAL: The number of reviewers required on pull requests. Must be >= 0. Defaults to 1. | `number` | `1` | no |
| <a name="input_push_ruleset_enabled"></a> [push\_ruleset\_enabled](#input\_push\_ruleset\_enabled) | OPTIONAL: Whether to create the push ruleset (file path/size/extension restrictions). Requires GitHub Team or Enterprise Cloud. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_push_ruleset_file_extension_restrictions"></a> [push\_ruleset\_file\_extension\_restrictions](#input\_push\_ruleset\_file\_extension\_restrictions) | OPTIONAL: File extensions blocked from being pushed, when push\_ruleset\_enabled = true. Defaults to none. | `list(string)` | `[]` | no |
| <a name="input_push_ruleset_file_path_restrictions"></a> [push\_ruleset\_file\_path\_restrictions](#input\_push\_ruleset\_file\_path\_restrictions) | OPTIONAL: File path patterns blocked from being pushed, when push\_ruleset\_enabled = true. Defaults to none. | `list(string)` | `[]` | no |
| <a name="input_push_ruleset_max_file_size_mb"></a> [push\_ruleset\_max\_file\_size\_mb](#input\_push\_ruleset\_max\_file\_size\_mb) | OPTIONAL: Maximum file size (MB, 1-100) allowed in a push, when push\_ruleset\_enabled = true. Defaults to 'null' (no limit). | `number` | `null` | no |
| <a name="input_require_code_owner_review"></a> [require\_code\_owner\_review](#input\_require\_code\_owner\_review) | OPTIONAL: Whether pull requests to the default branch need approval from a code owner. Only enforced for paths covered by a CODEOWNERS file - with no CODEOWNERS file it has no effect. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_require_conventional_commits"></a> [require\_conventional\_commits](#input\_require\_conventional\_commits) | OPTIONAL: Whether to enforce conventional commit messages on every branch except the default branch (which may carry non-conforming merge commits). Defaults to 'true'. Uses the commit\_message\_pattern rule, which GitHub restricts to repositories owned by a GitHub Enterprise Cloud account - has no effect unless enterprise\_features\_enabled is also 'true'. | `bool` | `true` | no |
| <a name="input_require_last_push_approval"></a> [require\_last\_push\_approval](#input\_require\_last\_push\_approval) | OPTIONAL: Whether the most recent pusher to a pull request must have their changes approved by someone else. Set to 'false' for solo-maintained repositories, where nobody else can approve. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_require_signed_commits"></a> [require\_signed\_commits](#input\_require\_signed\_commits) | OPTIONAL: Whether commits must use git cryptographic signatures. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_require_signed_tags"></a> [require\_signed\_tags](#input\_require\_signed\_tags) | OPTIONAL: Whether tags must use git cryptographic signatures. Defaults to 'true'. | `bool` | `true` | no |
| <a name="input_required_status_checks"></a> [required\_status\_checks](#input\_required\_status\_checks) | OPTIONAL: Status checks that must pass before merging. Each entry is { context, integration\_id }. Defaults to a single check named 'terraform-pull-request' - the aggregator job gating PRs on the terraform test pipeline. NOTE: the default is a required check, so PRs cannot merge until a workflow reporting that context exists; set to [] if the repository does not use it. | <pre>list(object({<br/>    context        = string<br/>    integration_id = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "context": "terraform-pull-request"<br/>  }<br/>]</pre> | no |
| <a name="input_ruleset_bypass_actors"></a> [ruleset\_bypass\_actors](#input\_ruleset\_bypass\_actors) | OPTIONAL: Actors allowed to bypass the repo's rulesets.<br/>actor\_type one of: RepositoryRole, Team, Integration, OrganizationAdmin,<br/>DeployKey, EnterpriseOwner, User. actor\_id is required for RepositoryRole<br/>(2 maintain, 4 write, 5 admin), Team, Integration (App ID) and User<br/>(numeric user ID); see the github\_repository\_ruleset docs.<br/>rulesets optionally restricts which rulesets the actor applies to - one<br/>or more of: branch\_protection, commit\_signing, commit\_signing\_tags,<br/>conventional\_commits, push\_protection. Leave unset to bypass all of them. | <pre>list(object({<br/>    actor_id    = optional(number)<br/>    actor_type  = string<br/>    bypass_mode = optional(string, "always")<br/>    rulesets    = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_source_template"></a> [source\_template](#input\_source\_template) | OPTIONAL: Details to use for a source template repository. Defaults to 'null' and will not be used. | <pre>object({<br/>    owner      = string<br/>    repository = string<br/>  })</pre> | `null` | no |
| <a name="input_squash_merge_commit_message"></a> [squash\_merge\_commit\_message](#input\_squash\_merge\_commit\_message) | OPTIONAL: What to use for squash merge commit message. One of 'PR\_BODY', 'COMMIT\_MESSAGES', or 'BLANK'. Defaults to 'COMMIT\_MESSAGES' - GitHub only allows squash\_merge\_commit\_title = 'COMMIT\_OR\_PR\_TITLE' paired with squash\_merge\_commit\_message = 'COMMIT\_MESSAGES'. | `string` | `"COMMIT_MESSAGES"` | no |
| <a name="input_squash_merge_commit_title"></a> [squash\_merge\_commit\_title](#input\_squash\_merge\_commit\_title) | OPTIONAL: What to use for squash merge commit title. One of 'PR\_TITLE' or 'COMMIT\_OR\_PR\_TITLE'. Defaults to 'COMMIT\_OR\_PR\_TITLE'. | `string` | `"COMMIT_OR_PR_TITLE"` | no |
| <a name="input_strict_required_status_checks"></a> [strict\_required\_status\_checks](#input\_strict\_required\_status\_checks) | OPTIONAL: Whether branches must be up to date with the default branch before merging (GitHub's 'require branches to be up to date'). Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | OPTIONAL: Teams to attach to the repository, keyed by the team's slug<br/>(when referencing an existing team) or desired slug (when creating one).<br/>Defaults to {}.<br/><br/>- permission: one of pull, triage, push, maintain, admin, or an existing<br/>  custom repository role's name (not validated here - this module is<br/>  repo-scoped and does not create org-level custom roles).<br/>- create: if true, creates the team (github\_team); if false, looks up an<br/>  existing team by slug and only attaches the permission.<br/>- name/description/privacy/parent\_team\_id: used only when create = true.<br/>  parent\_team\_id is the numeric ID or slug of an existing team (not one<br/>  created in the same call).<br/>- idp\_group\_id/idp\_group\_name/idp\_group\_description: links the team to an<br/>  already-existing Entra ID group. idp\_group\_name is required under<br/>  saml\_team\_sync or enterprise\_managed\_users; idp\_group\_id (the raw Entra<br/>  object ID) is additionally required under saml\_team\_sync, and ignored<br/>  under enterprise\_managed\_users (resolved from idp\_group\_name instead).<br/>- members: optional list of { username, role } managed via<br/>  github\_team\_membership. Only valid when idp\_group\_name is null - once<br/>  IdP-linked, GitHub requires membership changes via the identity<br/>  provider, not Terraform. | <pre>map(object({<br/>    permission            = string<br/>    create                = optional(bool, false)<br/>    name                  = optional(string)<br/>    description           = optional(string)<br/>    privacy               = optional(string, "closed")<br/>    parent_team_id        = optional(string)<br/>    idp_group_id          = optional(string)<br/>    idp_group_name        = optional(string)<br/>    idp_group_description = optional(string)<br/>    members = optional(list(object({<br/>      username = string<br/>      role     = optional(string, "member")<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | OPTIONAL: Topics to apply to the repository. Defaults to none. | `list(string)` | `[]` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | OPTIONAL: Repository visibility. One of 'private' or 'internal'. The 'internal' option requires GitHub Enterprise Cloud or GitHub Enterprise Server 2.20+. | `string` | `"private"` | no |
| <a name="input_web_commit_signoff_required"></a> [web\_commit\_signoff\_required](#input\_web\_commit\_signoff\_required) | OPTIONAL: Whether contributors must sign off on commits made through GitHub's web interface. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_wiki_enabled"></a> [wiki\_enabled](#input\_wiki\_enabled) | OPTIONAL: Whether or not GitHub Wiki is enabled on the repository. Defaults to 'false'. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_default_branch"></a> [default\_branch](#output\_default\_branch) | Name of the repository's default branch. |
| <a name="output_issue_labels"></a> [issue\_labels](#output\_issue\_labels) | Names of the issue labels created on the repository. |
| <a name="output_repository_full_name"></a> [repository\_full\_name](#output\_repository\_full\_name) | Full name of the repository, in '<owner>/<name>' format. |
| <a name="output_repository_html_url"></a> [repository\_html\_url](#output\_repository\_html\_url) | URL to the repository on github.com. |
| <a name="output_repository_http_clone_url"></a> [repository\_http\_clone\_url](#output\_repository\_http\_clone\_url) | HTTPS URL to clone the repository. |
| <a name="output_repository_id"></a> [repository\_id](#output\_repository\_id) | Numeric ID of the repository. |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | Name of the repository. |
| <a name="output_repository_node_id"></a> [repository\_node\_id](#output\_repository\_node\_id) | GraphQL node ID of the repository. |
| <a name="output_repository_ssh_clone_url"></a> [repository\_ssh\_clone\_url](#output\_repository\_ssh\_clone\_url) | SSH URL to clone the repository. |
| <a name="output_ruleset_ids"></a> [ruleset\_ids](#output\_ruleset\_ids) | IDs of the rulesets created for the repository, keyed by ruleset name. Rulesets that are disabled are omitted. |
| <a name="output_team_ids"></a> [team\_ids](#output\_team\_ids) | Team IDs attached to the repository, keyed by team key from var.teams. |
| <a name="output_team_slugs"></a> [team\_slugs](#output\_team\_slugs) | Team slugs attached to the repository, keyed by team key from var.teams. |
<!-- END_TF_DOCS -->

## Contributing

Contributions are welcome. Please read the [Code of Conduct](./CODE_OF_CONDUCT.md) before contributing.

## License

This project is licensed under the terms of the [GPL-3.0 license](./LICENSE).
