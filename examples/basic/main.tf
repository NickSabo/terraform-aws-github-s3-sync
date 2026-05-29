# Example: Sync a GitHub repo to S3
#
# First use — creates the OIDC provider:
#
#   module "repo_sync" {
#     source      = "github.com/NickSabo/terraform-aws-github-s3-sync"
#     github_org  = "NickSabo"
#     github_repo = "my-app"
#     bucket_name = "my-app-code"
#   }
#
# Second repo — reuses the existing OIDC provider:
#
#   module "another_sync" {
#     source               = "github.com/NickSabo/terraform-aws-github-s3-sync"
#     github_org           = "NickSabo"
#     github_repo          = "another-repo"
#     bucket_name          = "another-repo-code"
#     create_oidc_provider = false
#   }
#
# After applying, add the role_arn output as a GitHub secret (AWS_ROLE_ARN),
# then add this workflow to your repo at .github/workflows/sync-s3.yml:
#
#   name: Sync to S3
#   on:
#     push:
#       branches: [main]
#   permissions:
#     id-token: write
#     contents: read
#   jobs:
#     sync:
#       runs-on: ubuntu-latest
#       steps:
#         - uses: actions/checkout@v4
#         - uses: aws-actions/configure-aws-credentials@v4
#           with:
#             role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
#             aws-region: us-east-2
#         - run: aws s3 sync . s3://YOUR_BUCKET_NAME --delete --exclude ".git/*"

terraform {
  backend "s3" {
    bucket       = "nicksabo-terraform"
    key          = "github-s3-sync-example/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

module "repo_sync" {
  source      = "github.com/NickSabo/terraform-aws-github-s3-sync"
  github_org  = "NickSabo"
  github_repo = "terraform"
  bucket_name = "nicksabo-terraform-code"
}

output "role_arn" {
  value = module.repo_sync.role_arn
}
