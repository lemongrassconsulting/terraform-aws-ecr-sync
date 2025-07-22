variable "namespace" {
  description = "Namespace for all resources."
  type        = string
}

variable "config" {
  description = "A map defining the sync behavior, including mode, repositories and repo_defaults."
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

variable "task_image_uri" {
  description = "URI of the container image for the sync task."
  type        = string
}

variable "task_image_tag" {
  description = "Tag of the container image for the sync task."
  type        = string
  default     = "latest"
}

variable "task_log_retention" {
  description = "The task's CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "task_log_kms_key_id" {
  description = "The ARN of the KMS key to use for encrypting the task's CloudWatch log group. Defaults to the AWS-managed key if null."
  type        = string
  default     = null
}

variable "task_ephemeral_storage_size" {
  description = "Size of the ephemeral storage for the Fargate task in GiB."
  type        = number
  default     = null
}

# --- Optional Networking Configuration ---

variable "task_vpc_id" {
  description = "Optional: The ID of the VPC to deploy the Fargate task into. If not provided, the default VPC is used. Providing a VPC ID is required for private deployments."
  type        = string
  default     = null
}

variable "task_subnet_ids" {
  description = "Optional: A list of subnet IDs to deploy the Fargate task into. Required if a `task_vpc_id` is provided."
  type        = list(string)
  default     = null
}

variable "task_security_groups" {
  description = "Optional: A list of security group IDs to associate with the Fargate task. If a `task_vpc_id` is provided but this is left null, a new security group will be created automatically with appropriate egress rules."
  type        = list(string)
  default     = null
}

variable "task_assign_public_ip" {
  description = "Whether to assign a public IP to the Fargate task. Set to `false` for private subnets that use VPC endpoints. This variable also controls the egress rules of the auto-created security group: `true` allows internet access, while `false` restricts egress to the VPC's CIDR block for endpoint communication."
  type        = bool
  default     = true
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

variable "s3_bucket_name" {
  description = "Optional: The name of the S3 bucket to create. If not provided, a name will be generated."
  type        = string
  default     = null
}
