output "repository_id" {
  description = "Numeric ID of the repository."
  value       = github_repository.this.repo_id
}

output "repository_node_id" {
  description = "GraphQL node ID of the repository."
  value       = github_repository.this.node_id
}

output "repository_name" {
  description = "Name of the repository."
  value       = github_repository.this.name
}

output "repository_full_name" {
  description = "Full name of the repository, in '<owner>/<name>' format."
  value       = github_repository.this.full_name
}

output "repository_html_url" {
  description = "URL to the repository on github.com."
  value       = github_repository.this.html_url
}

output "repository_ssh_clone_url" {
  description = "SSH URL to clone the repository."
  value       = github_repository.this.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "HTTPS URL to clone the repository."
  value       = github_repository.this.http_clone_url
}

output "team_ids" {
  description = "Team IDs attached to the repository, keyed by team key from var.teams."
  value       = local.team_ids_by_key
}

output "team_slugs" {
  description = "Team slugs attached to the repository, keyed by team key from var.teams."
  value       = local.team_slugs_by_key
}

output "default_branch" {
  description = "Name of the repository's default branch."
  value       = github_branch_default.this.branch
}

output "ruleset_ids" {
  description = "IDs of the rulesets created for the repository, keyed by ruleset name. Rulesets that are disabled are omitted."
  value = merge(
    { branch_protection = github_repository_ruleset.branch_protection.ruleset_id },
    { for r in github_repository_ruleset.commit_signing : "commit_signing" => r.ruleset_id },
    { for r in github_repository_ruleset.commit_signing_tags : "commit_signing_tags" => r.ruleset_id },
    { for r in github_repository_ruleset.conventional_commits : "conventional_commits" => r.ruleset_id },
    { for r in github_repository_ruleset.push_protection : "push_protection" => r.ruleset_id },
  )
}

output "issue_labels" {
  description = "Names of the issue labels created on the repository."
  value       = keys(github_issue_label.this)
}
