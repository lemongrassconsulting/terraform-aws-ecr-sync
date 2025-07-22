terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Or your desired region
}

module "ecr_pull_sync" {
  source = "../modules/ecr-sync"

  namespace = var.namespace
  config    = var.config
  schedule  = var.schedule

  task_image_uri        = var.task_image_uri
  task_image_tag        = var.task_image_tag
  task_log_retention    = var.task_log_retention
  task_log_kms_key_id   = var.task_log_kms_key_id
  task_vpc_id           = var.task_vpc_id
  task_subnet_ids       = var.task_subnet_ids
  task_security_groups  = var.task_security_groups
  task_assign_public_ip = var.task_assign_public_ip

  s3_bucket_kms_key_arn                            = var.s3_bucket_kms_key_arn
  s3_bucket_noncurrent_version_expiration_days     = var.s3_bucket_noncurrent_version_expiration_days
  s3_bucket_access_logging_target_bucket           = var.s3_bucket_access_logging_target_bucket
  s3_bucket_access_logging_target_prefix           = var.s3_bucket_access_logging_target_prefix
  s3_bucket_name                                   = var.s3_bucket_name
  s3_bucket_abort_incomplete_multipart_upload_days = var.s3_bucket_abort_incomplete_multipart_upload_days
}
