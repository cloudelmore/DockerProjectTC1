# Lets GitHub Actions on the gitops branch deploy to AWS without stored keys.
# GitHub proves who it is with a short-lived OIDC token, and AWS trades it
# for temporary credentials on the role below.

variable "github_repo" {
  description = "GitHub repository in owner/name form"
  type        = string
  default     = "cloudelmore/DockerProjectTC1"
}

variable "github_repo_with_ids" {
  description = "Repository with GitHub's numeric owner and repo IDs, as it appears in the OIDC subject"
  type        = string
  default     = "cloudelmore@312297302/DockerProjectTC1@1459102589"
}

variable "github_branch" {
  description = "Only workflows running on this branch can assume the role"
  type        = string
  default     = "gitops"
}

variable "create_github_oidc_provider" {
  description = "Set to false if this AWS account already has the GitHub OIDC provider"
  type        = bool
  default     = true
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # GitHub may send the subject in either format, so accept both:
          #   classic: repo:owner/repo:ref:refs/heads/branch
          #   with IDs: repo:owner@ownerId/repo@repoId:ref:refs/heads/branch
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}",
            "repo:${var.github_repo_with_ids}:ref:refs/heads/${var.github_branch}"
          ]
        }
      }
    }]
  })
}

# Push images to this project's two ECR repositories only
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${var.project_name}-github-actions-ecr"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = [
          aws_ecr_repository.frontend.arn,
          aws_ecr_repository.backend.arn
        ]
      }
    ]
  })
}

# Redeploy only this project's two ECS services
resource "aws_iam_role_policy" "github_actions_ecs" {
  name = "${var.project_name}-github-actions-ecs-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ]
      Resource = [
        "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.main.name}/*"
      ]
    }]
  })
}

output "github_actions_role_arn" {
  description = "Role ARN for the GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}