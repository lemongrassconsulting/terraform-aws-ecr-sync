terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  dest_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"

  # --- Transform config object into .env file format ---
  repo_defaults_vars = [
    for k, v in var.config.repo_defaults :
    v != null ? "APP_REPO_DEFAULTS__${upper(k)}=${v}" : null
  ]

  repos_vars = flatten([
    for i, repo in var.config.repos : [
      "APP_REPOS__${i}__SOURCE=${repo.source}",
      repo.destination != null ? "APP_REPOS__${i}__DESTINATION=${repo.destination}" : null,
      [for j, tag in repo.tags : "APP_REPOS__${i}__TAGS__${j}=${tag}"]
    ]
  ])

  base_vars = [
    "APP_MODE=${var.config.mode}",
    "APP_DEST_REGISTRY=${local.dest_registry}",
    "APP_IMAGE_TAG=${var.task_image_tag}"
  ]

  all_vars = compact(concat(
    local.base_vars,
    local.repo_defaults_vars,
    local.repos_vars
  ))

  env_file_content = join("\n", local.all_vars)

  # --- ECR Repository ARNs for IAM Policy ---
  # The list of source repository ARNs is constructed by parsing the source
  # string. The source can be a full ECR URI (e.g.,
  # <account_id>.dkr.ecr.<region>.amazonaws.com/<repo_name>) or a simple
  # repository name for repositories in the current account and region.
  source_repo_arns = distinct([
    for repo in var.config.repos :
    (
      strcontains(repo.source, ".dkr.ecr.") ?
      # It's a full URI
      format("arn:aws:ecr:%s:%s:repository/%s",
        element(split(".", element(split("/", repo.source), 0)), 3),
        element(split(".", element(split("/", repo.source), 0)), 0),
        join("/", slice(split("/", repo.source), 1, length(split("/", repo.source))))
      ) :
      # It's a simple name
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${repo.source}"
    )
  ])

  # The list of destination repository ARNs is constructed assuming that the
  # destination repositories are in the same AWS account and region where the
  # module is deployed. If a destination is not specified, it defaults to the
  # source repository name.
  destination_repo_arns = distinct([
    for repo in var.config.repos :
    "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${
      coalesce(
        repo.destination,
        (
          strcontains(repo.source, ".dkr.ecr.") ?
          # Extract repo name from full URI
          join("/", slice(split("/", repo.source), 1, length(split("/", repo.source)))) :
          # Or use the source as is (simple name)
          repo.source
        )
      )
    }"
  ])

  all_repo_arns = distinct(concat(local.source_repo_arns, local.destination_repo_arns))

  # --- IAM Policy Statements ---
  ecr_policy_statements = concat(
    [
      {
        Action   = ["ecr:GetAuthorizationToken"]
        Effect   = "Allow"
        Resource = "*"
      }
    ],
    # Read permissions
    length(local.all_repo_arns) > 0 ? [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
        ]
        Effect   = "Allow"
        Resource = local.all_repo_arns
      }
    ] : [],
    # Write permissions
    length(local.destination_repo_arns) > 0 ? [
      {
        Action = [
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Effect   = "Allow"
        Resource = local.destination_repo_arns
      }
    ] : [],
    # Create repository permission
    var.config.mode == "create" && length(local.destination_repo_arns) > 0 ? [
      {
        Action   = ["ecr:CreateRepository"]
        Effect   = "Allow"
        Resource = local.destination_repo_arns
      }
    ] : []
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Conditional Data Sources for Networking ---
data "aws_vpc" "default" {
  count   = var.task_vpc_id == null ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.task_subnet_ids == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# --- S3 Bucket for Environment File ---
resource "aws_s3_bucket" "config" {
  bucket        = var.s3_bucket_name == null ? "${var.namespace}-ecr-pull-sync-config-${data.aws_caller_identity.current.account_id}" : var.s3_bucket_name
  force_destroy = true
  #checkov:skip=CKV_AWS_144:Cross-region replication is not necessary for this bucket as it only stores a simple config file.
  #checkov:skip=CKV2_AWS_62:Notifications are not necessary for this bucket as it only stores a simple config file.
}

resource "aws_s3_bucket_logging" "config" {
  count = var.s3_bucket_access_logging_target_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.config.id

  target_bucket = var.s3_bucket_access_logging_target_bucket
  target_prefix = var.s3_bucket_access_logging_target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.s3_bucket_noncurrent_version_expiration_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.s3_bucket_abort_incomplete_multipart_upload_days
    }
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_bucket_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.s3_bucket_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "config" {
  bucket  = aws_s3_bucket.config.id
  key     = "config.env"
  content = local.env_file_content
  etag    = md5(local.env_file_content)
}

# --- Core Resources ---
resource "aws_cloudwatch_log_group" "this" {
  name = "/${var.namespace}/ecr-pull-sync"
  # checkov:skip=CKV_AWS_338: A 1-year log retention is not required for this non-critical, short-lived task.
  retention_in_days = var.task_log_retention
  # checkov:skip=CKV_AWS_158: KMS encryption is enabled by default by AWS or can be customized via log_kms_key_id.
  kms_key_id = var.task_log_kms_key_id
}

resource "aws_ecs_cluster" "this" {
  # checkov:skip=CKV_AWS_65: Container Insights is not necessary for this simple, non-critical scheduled task.
  name = "${var.namespace}-ecr-pull-sync"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.namespace}-ecr-pull-sync"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  #checkov:skip=CKV_AWS_336:Root file system access allowed for ephemeral containers to support crane

  container_definitions = jsonencode([
    {
      name  = "crane-wrapper"
      image = "${var.task_image_uri}:${var.task_image_tag}"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environmentFiles = [
        {
          type  = "s3"
          value = aws_s3_object.config.arn
        }
      ]
    }
  ])

  dynamic "ephemeral_storage" {
    for_each = var.task_ephemeral_storage_size != null ? [1] : []
    content {
      size_in_gib = var.task_ephemeral_storage_size
    }
  }
}

# --- IAM Resources ---
resource "aws_iam_role" "task_execution_role" {
  name = "${var.namespace}-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "s3_config_access" {
  name        = "${var.namespace}-s3-config-access-policy"
  description = "Allows the ECS task to read the config file from S3."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = aws_s3_object.config.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_config_access" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.s3_config_access.arn
}

resource "aws_iam_policy" "task_execution_kms_policy" {
  count = var.task_log_kms_key_id != null ? 1 : 0
  name  = "${var.namespace}-task-execution-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = var.task_log_kms_key_id
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_kms_policy" {
  count      = var.task_log_kms_key_id != null ? 1 : 0
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_kms_policy[0].arn
}

resource "aws_iam_policy" "s3_kms_policy" {
  count = var.s3_bucket_kms_key_arn != null ? 1 : 0
  name  = "${var.namespace}-s3-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "kms:Decrypt"
        Effect   = "Allow"
        Resource = var.s3_bucket_kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_kms_policy" {
  count      = var.s3_bucket_kms_key_arn != null ? 1 : 0
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3_kms_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "task_execution_s3_kms_policy" {
  count      = var.s3_bucket_kms_key_arn != null ? 1 : 0
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.s3_kms_policy[0].arn
}


resource "aws_iam_role" "task_role" {
  name = "${var.namespace}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "task_policy" {
  name        = "${var.namespace}-task-policy"
  description = "Policy for the ECR Pull Sync task."
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.ecr_policy_statements
  })
}

resource "aws_iam_role_policy_attachment" "task_role_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_policy" "task_kms_policy" {
  count = var.config.repo_defaults.kms_key_arn != null ? 1 : 0
  name  = "${var.namespace}-task-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Effect   = "Allow"
        Resource = var.config.repo_defaults.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_kms_policy" {
  count      = var.config.repo_defaults.kms_key_arn != null ? 1 : 0
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_kms_policy[0].arn
}

# --- EventBridge Scheduler ---
resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.namespace}-ecr-pull-sync"
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "ecs-fargate-task"
  arn       = aws_ecs_cluster.this.arn
  role_arn  = aws_iam_role.eventbridge_role.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.this.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = var.task_subnet_ids == null ? data.aws_subnets.default[0].ids : var.task_subnet_ids
      assign_public_ip = var.task_assign_public_ip
    }
  }
}

resource "aws_iam_role" "eventbridge_role" {
  name = "${var.namespace}-eventbridge-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_policy" {
  name        = "${var.namespace}-eventbridge-policy"
  description = "Policy for EventBridge to run ECS tasks."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ecs:RunTask"
        Effect   = "Allow"
        Resource = aws_ecs_task_definition.this.arn
        Condition = {
          StringEquals = {
            "ecs:cluster" = aws_ecs_cluster.this.arn
          }
        }
      },
      {
        Action = "iam:PassRole"
        Effect = "Allow"
        Resource = [
          aws_iam_role.task_role.arn,
          aws_iam_role.task_execution_role.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_policy" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}
