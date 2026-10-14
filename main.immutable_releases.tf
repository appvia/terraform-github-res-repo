# Keep the read-only GET check and the PUT enablement resource together: they form
# one workflow, with the observed status driving replacement of the Terraform marker.
# Co-locating them makes that dependency clear without switching between files.
data "external" "immutable_releases_status" {
  count = var.immutable_releases ? 1 : 0
  program = ["bash", "-c", <<-SCRIPT
    set -euo pipefail
    REPO=$(jq -er '.REPO' -)
    gh api "/repos/$REPO/immutable-releases" |
      jq -ce 'if (.enabled | type) == "boolean" then {enabled: (.enabled | tostring)} else error("Expected a boolean immutable releases status") end'
  SCRIPT
  ]
  query = {
    # Defer the first status check until the repository exists.
    REPO = github_repository.this[0].full_name
  }
}

resource "terraform_data" "immutable_releases" {
  count = var.immutable_releases ? 1 : 0
  # A status change reruns enablement; destroying this marker does not disable releases.
  triggers_replace = [
    data.external.immutable_releases_status[0].result.enabled == "true"
  ]

  provisioner "local-exec" {
    # tflint-ignore: terraform_list_order
    interpreter = ["bash", "-c"]
    command     = "gh api --method PUT \"/repos/$REPO/immutable-releases\""
    environment = {
      REPO = github_repository.this[0].full_name
    }
  }
}
