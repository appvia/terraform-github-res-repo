#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

module "repo" {
  source = "../.."

  repo_name   = "example-repo"
  description = "Example repository managed by terraform-github-res-repo."
  visibility  = "private"

  teams = {
    platform = {
      permission = "admin"
      create     = true
      name       = "platform"
    }
    readers = {
      permission = "pull"
      create     = false
    }
  }
}
