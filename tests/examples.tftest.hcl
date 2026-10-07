# Plans the real examples/basic configuration end-to-end, catching breakage
# in the example itself (not just the module's own logic). The example's
# "readers" team has create = false, so it depends on a live
# data.github_team.existing lookup - override_data pins it to a deterministic
# value so the plan can be asserted against.

mock_provider "github" {}

run "plan_basic_example" {
  command = plan
  module {
    source = "./examples/basic"
  }
  override_data {
    target          = module.repo.data.github_team.existing["readers"]
    override_during = plan
    values = {
      id   = "99"
      slug = "readers"
    }
  }
  assert {
    condition     = module.repo.team_ids["readers"] == "99"
    error_message = "readers (create=false) team id should reflect the existing-team lookup override"
  }
  assert {
    condition     = module.repo.repository_name == "example-repo"
    error_message = "example repo_name wiring broken"
  }
}

run "apply_basic_example" {
  command = apply
  module {
    source = "./examples/basic"
  }
  override_data {
    target = module.repo.data.github_team.existing["readers"]
    values = {
      id   = "99"
      slug = "readers"
    }
  }
  assert {
    condition     = module.repo.team_ids["readers"] == "99"
    error_message = "readers (create=false) team id should reflect the existing-team lookup override after apply"
  }
  assert {
    condition     = module.repo.repository_name == "example-repo"
    error_message = "example repo_name wiring broken after apply"
  }
}
