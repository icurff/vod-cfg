locals {
  oidc_provider_id = replace(var.oidc_provider_url, "https://", "")
}

# ── Backend IRSA Role (S3 read/write + Secrets Manager read) ──
resource "aws_iam_role" "backend" {
  name = "streamforge-backend-irsa-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${local.oidc_provider_id}:sub" = [
            "system:serviceaccount:streamforge-${var.environment}:backend-sa",
            "system:serviceaccount:streamforge-${var.environment}:vod-be-sa",
            "system:serviceaccount:streamforge-${var.environment}:backend"
          ]
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "backend_s3" {
  name = "backend-permissions-policy"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:${var.aws_account_id}:secret:streamforge/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/streamforge-*-${var.environment}",
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/streamforge-*-${var.environment}/index/*"
        ]
      }
    ]
  })
}

# ── Transcode Worker IRSA Role (S3 + SQS + Secrets Manager + DynamoDB) ──
resource "aws_iam_role" "worker" {
  name = "streamforge-worker-irsa-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "${local.oidc_provider_id}:sub" = [
              "system:serviceaccount:streamforge-${var.environment}:worker-sa",
              "system:serviceaccount:streamforge-${var.environment}:transcode-worker-sa",
              "system:serviceaccount:streamforge-${var.environment}:worker",
              "system:serviceaccount:keda:keda-operator"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/streamforge-worker-irsa-${var.environment}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "worker_permissions" {
  name = "worker-permissions-policy"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:${var.aws_account_id}:secret:streamforge/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/streamforge-*-${var.environment}",
          "arn:aws:dynamodb:*:${var.aws_account_id}:table/streamforge-*-${var.environment}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = "arn:aws:iam::${var.aws_account_id}:role/streamforge-worker-irsa-${var.environment}"
      }
    ]
  })
}

# ── Cluster Autoscaler IRSA Role ──
resource "aws_iam_role" "cluster_autoscaler" {
  name = "streamforge-cluster-autoscaler-irsa-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_id}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          "${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "cluster_autoscaler_policy" {
  name = "cluster-autoscaler-policy"
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })
}
