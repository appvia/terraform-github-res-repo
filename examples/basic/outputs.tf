output "repository_html_url" {
  description = "URL of the example repository."
  value       = module.repo.repository_html_url
}

output "team_slugs" {
  description = "Slugs of the teams attached to the example repository."
  value       = module.repo.team_slugs
}
