output "role_arn" {
  description = "IAM role ARN to set as the AWS_ROLE_ARN GitHub secret"
  value       = aws_iam_role.github_actions.arn
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.sync.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.sync.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}

output "next_steps" {
  description = "Post-apply instructions"
  value       = <<-EOT

    ============================================================
    NEXT STEPS
    ============================================================

    1. Add this GitHub repo secret:
       Name:  AWS_ROLE_ARN
       Value: ${aws_iam_role.github_actions.arn}
       URL:   https://github.com/${var.github_org}/${var.github_repo}/settings/secrets/actions/new

    2. Add .github/workflows/sync-s3.yml to your repo:

       name: Sync to S3
       on:
         push:
           branches: [${var.branch}]
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
                 role-to-assume: ${"${{ secrets.AWS_ROLE_ARN }}"}
                 aws-region: us-east-2
             - run: aws s3 sync . s3://${var.bucket_name} --delete --exclude ".git/*"

    3. Push to ${var.branch} and the sync will run automatically!

    ============================================================
  EOT
}
