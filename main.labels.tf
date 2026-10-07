resource "github_issue_label" "this" {
  for_each    = var.issue_labels
  repository  = github_repository.this.name
  name        = each.key
  color       = each.value.color
  description = each.value.description
}
