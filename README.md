# terraform-aws-github-s3-sync

Terraform module that sets up everything needed to sync a GitHub repo to an S3 bucket using GitHub Actions with OIDC authentication. No long-lived AWS credentials required.

## What it creates

- S3 bucket (with optional versioning)
- GitHub OIDC provider (one per AWS account, toggle with `create_oidc_provider`)
- IAM role scoped to the specific repo and branch
- IAM policy with least-privilege S3 access

## Usage

```hcl
module "repo_sync" {
  source      = "github.com/NickSabo/terraform-aws-github-s3-sync"
  github_org  = "NickSabo"
  github_repo = "my-repo"
  bucket_name = "my-repo-code"
}
```

After applying:

1. Copy the `role_arn` output
2. Add it as a GitHub repo secret called `AWS_ROLE_ARN`
3. Add the workflow file to your repo (see below)

### GitHub Actions Workflow

Add `.github/workflows/sync-s3.yml` to the repo you want to sync:

```yaml
name: Sync to S3
on:
  push:
    branches: [main]
permissions:
  id-token: write
  contents: read
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-2
      - run: aws s3 sync . s3://YOUR_BUCKET --delete --exclude ".git/*"
```

### Multiple repos

The OIDC provider is a one-per-account resource. Set `create_oidc_provider = false` for the second repo onward:

```hcl
module "second_repo" {
  source               = "github.com/NickSabo/terraform-aws-github-s3-sync"
  github_org           = "NickSabo"
  github_repo          = "another-repo"
  bucket_name          = "another-repo-code"
  create_oidc_provider = false
}
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `github_org` | GitHub org or username | (required) |
| `github_repo` | Repository name | (required) |
| `bucket_name` | S3 bucket name | (required) |
| `branch` | Branch allowed to sync | `"main"` |
| `create_oidc_provider` | Create the GitHub OIDC provider | `true` |
| `enable_versioning` | Enable S3 bucket versioning | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | IAM role ARN for the `AWS_ROLE_ARN` GitHub secret |
| `bucket_name` | S3 bucket name |
| `bucket_arn` | S3 bucket ARN |
| `oidc_provider_arn` | GitHub OIDC provider ARN |
