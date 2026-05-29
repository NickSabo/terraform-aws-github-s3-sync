terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Look up existing OIDC provider if we're not creating one
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# Create OIDC provider if it doesn't exist yet
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# S3 bucket for synced repo contents
resource "aws_s3_bucket" "sync" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "sync" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.sync.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role that GitHub Actions assumes via OIDC
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.github_repo}-sync"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.branch}"
          }
        }
      }
    ]
  })
}

# Policy: allow s3 sync to the bucket only
resource "aws_iam_role_policy" "s3_sync" {
  name = "s3-sync"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.sync.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.sync.arn}/*"
      }
    ]
  })
}
