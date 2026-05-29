variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to sync repo contents to"
  type        = string
}

variable "branch" {
  description = "Branch that is allowed to trigger the sync"
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider. Set to false if one already exists in your account."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}
