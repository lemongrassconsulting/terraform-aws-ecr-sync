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
  description = "Optional: The ID of the VPC to deploy the Fargate task into. If not provided, the default VPC is used."
  type        = string
  default     = null
}

variable "task_subnet_ids" {
  description = "Optional: A list of subnet IDs to deploy the Fargate task into. Required if vpc_id is provided."
  type        = list(string)
  default     = null
}

variable "task_assign_public_ip" {
  description = "Whether to assign a public IP to the Fargate task. Should be false for private subnets."
  type        = bool
  default     = true
}
