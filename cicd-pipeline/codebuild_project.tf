resource "aws_iam_role" "codebuild-role" {
  name = "codebuild-${var.application-name}-${var.branch}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "codebuild-policy" {

  // allow codebuild to log to cloudwatch
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    effect = "Allow"

    resources = [
      "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/*",
      "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/*"
    ]
  }

  // allow codebuild to put artifacts in s3
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    effect = "Allow"

    resources = [
      "arn:aws:s3:::*"
    ]
  }

  // allow codebuild to publish test reports
  statement {
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]

    effect = "Allow"

    resources = [
      "arn:aws:codebuild:us-east-1:*:report-group/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild-role-policy" {
  role = aws_iam_role.codebuild-role.name

  policy = data.aws_iam_policy_document.codebuild-policy.json
}

resource "aws_codebuild_project" "codebuild-project" {
  name = "${var.application-name}-${var.branch}"
  description = var.application-name

  # in minutes
  build_timeout = "10"
  service_role = aws_iam_role.codebuild-role.arn

  source {
    type = "CODEPIPELINE"
  }

  source_version = var.branch

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:4.0"
    type = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  tags = {
    Projectr = var.application-name
  }
}