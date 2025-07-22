# This file contains example configuration for the basic-deployment environment.
# Terraform automatically loads variables from files ending in .auto.tfvars.

# --- Required Configuration ---
namespace      = "example-ecr-sync"
task_image_uri = "111122223333.dkr.ecr.us-east-1.amazonaws.com/ecr-pull-sync" # Replace with your image URI

# --- Main Application Configuration ---
# This object defines the entire behavior of the sync application.
config = {
  mode = "create" # "create" or "refresh"
  repos = [
    {
      source = "111122223333.dkr.ecr.us-east-1.amazonaws.com/my-app"
      tags   = ["v1.*", "latest"]
    },
    {
      source      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/another-app"
      destination = "renamed-app"
      tags        = ["stable"]
    }
  ]
  repo_defaults = {
    scan_on_push     = true
    tag_immutability = true
    encryption_type  = "AES256" # "AES256" or "KMS"
    # kms_key_arn      = "arn:aws:kms:us-east-1:111122223333:key/your-repo-kms-key-id"
  }
}

# --- Optional: Task Scheduling and Versioning ---
# schedule       = "rate(1 hour)"
# task_image_tag = "latest"

# --- Optional: Task Logging ---
# task_log_retention  = 60
# task_log_kms_key_id = "arn:aws:kms:us-east-1:111122223333:key/your-kms-key-id"

# --- Optional: Private Networking ---
# The module can deploy the Fargate task into a specific VPC.
#
# If you provide a `task_vpc_id` but leave `task_security_groups` as null, the module
# will automatically create a security group with appropriate egress rules.
# The behavior of these rules is controlled by `task_assign_public_ip`:
#  - true:  Allows all outbound traffic to the internet (0.0.0.0/0).
#  - false: Restricts outbound traffic to the VPC's CIDR block on port 443 (HTTPS),
#           ideal for use with VPC endpoints.
#
# To deploy into a private VPC, uncomment and configure the following variables.
# Ensure your VPC has the necessary VPC endpoints for ECR, CloudWatch Logs, and S3.
#
# task_vpc_id           = "vpc-0123456789abcdef0"
# task_subnet_ids       = ["subnet-0123456789abcdef0", "subnet-fedcba9876543210"]
# task_assign_public_ip = false
#
# To use your own security groups, provide their IDs below.
# task_security_groups  = ["sg-0123456789abcdef0"]

# --- Optional: S3 Bucket Configuration ---
# s3_bucket_name = "my-custom-ecr-sync-config-bucket"
# s3_bucket_kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/your-s3-kms-key-id"
# s3_bucket_noncurrent_version_expiration_days = 60
# s3_bucket_access_logging_target_bucket = "your-access-log-bucket"
# s3_bucket_access_logging_target_prefix = "ecr-sync-logs/"
# s3_bucket_abort_incomplete_multipart_upload_days = 14
