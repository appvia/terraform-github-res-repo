variable "repo_name" {
  description = "REQUIRED: Name of the GitHub repository to create."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{1,100}$", var.repo_name))
    error_message = "name must be 1-100 characters and contain only letters, numbers, hyphens, underscores and periods."
  }
}
