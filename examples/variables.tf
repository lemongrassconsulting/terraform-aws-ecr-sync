# This file defines the input variables for the ECR Pull Sync module example.
# These variables are consumed by the module in `main.tf`.

variable "namespace" {
  description = "Namespace for all resources in this environment."
  type        = string
}

variable "config" {
  description = "The main configuration object for the sync application."
  type = object({
    mode = optional(string, "create")
    repos = optional(list(object({
      source      = string
      destination = optional(string)
      tags        = list(string)
    })), [])
    repo_defaults = optional(object({
      scan_on_push     = optional(bool, true)
      tag_immutability = optional(bool, true)
      encryption_type  = optional(string, "AES256")
      kms_key_arn      = optional(string)
    }), {})
  })
  default = {}
}

variable "schedule" {
  description = "Cron expression for the Fargate task."
  type        = string
  default     = "rate(15 minutes)"
}

# --- Task Configuration ---
variable "task_image_uri" {
  description = "URI of the container image for the sync task."
  type        = string
}

variable "task_image_tag" {
  description = "Tag of the container image for the sync task."
  type        = string
  default     = "latest"
}

variable "task_log_kms_key_id" {
  description = "Optional: The ARN of the KMS key to use for encrypting the task's CloudWatch log group."
  type        = string
  default     = null
}

variable "task_log_retention" {
  description = "Optional: The task's CloudWatch log retention in days."
  type        = number
  default     = 30
}

# --- Optional Task Networking ---
variable "task_vpc_id" {
  description = "Optional: The ID of the VPC to deploy the task into. If null, uses the default VPC."
  type        = string
  default     = null
}

variable "task_subnet_ids" {
  description = "Optional: A list of subnet IDs to deploy the task into. Required if vpc_id is set."
  type        = list(string)
  default     = null
}

variable "task_assign_public_ip" {
  description = "Whether to assign a public IP to the Fargate task. Should be false for private subnets."
  type        = bool
  default     = true
}

# --- Optional S3 Bucket Configuration ---
variable "s3_bucket_name" {
  description = "Optional: The name of the S3 bucket to create. If not provided, a name will be generated."
  type        = string
  default     = null
}

variable "s3_bucket_kms_key_arn" {
  description = "Optional: The ARN of the KMS key to use for encrypting the S3 bucket. If not provided, AES256 encryption will be used."
  type        = string
  default     = null
}

variable "s3_bucket_noncurrent_version_expiration_days" {
  description = "Optional: The number of days to keep noncurrent object versions in the S3 bucket. Defaults to 30."
  type        = number
  default     = 30
}

variable "s3_bucket_abort_incomplete_multipart_upload_days" {
  description = "Optional: The number of days after which to abort incomplete multipart uploads. Defaults to 7."
  type        = number
  default     = 7
}

variable "s3_bucket_access_logging_target_bucket" {
  description = "Optional: The name of the S3 bucket to use for access logging. If not provided, access logging will be disabled."
  type        = string
  default     = null
}

variable "s3_bucket_access_logging_target_prefix" {
  description = "Optional: The prefix to use for access logs. Defaults to 'log/'."
  type        = string
  default     = "log/"
}
