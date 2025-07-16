# basic-deployment

This directory contains a basic example of how to use the `ecr-pull-sync` module.

<!-- BEGIN_TF_DOCS -->
<!-- prettier-ignore-start -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr_pull_sync"></a> [ecr\_pull\_sync](#module\_ecr\_pull\_sync) | ../modules/ecr-sync | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for all resources in this environment. | `string` | n/a | yes |
| <a name="input_task_image_uri"></a> [task\_image\_uri](#input\_task\_image\_uri) | URI of the container image for the sync task. | `string` | n/a | yes |
| <a name="input_config"></a> [config](#input\_config) | The main configuration object for the sync application. | <pre>object({<br/>    mode = optional(string, "create")<br/>    repos = optional(list(object({<br/>      source      = string<br/>      destination = optional(string)<br/>      tags        = list(string)<br/>    })), [])<br/>    repo_defaults = optional(object({<br/>      scan_on_push     = optional(bool, true)<br/>      tag_immutability = optional(bool, true)<br/>      encryption_type  = optional(string, "AES256")<br/>      kms_key_arn      = optional(string)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_s3_bucket_abort_incomplete_multipart_upload_days"></a> [s3\_bucket\_abort\_incomplete\_multipart\_upload\_days](#input\_s3\_bucket\_abort\_incomplete\_multipart\_upload\_days) | Optional: The number of days after which to abort incomplete multipart uploads. Defaults to 7. | `number` | `7` | no |
| <a name="input_s3_bucket_access_logging_target_bucket"></a> [s3\_bucket\_access\_logging\_target\_bucket](#input\_s3\_bucket\_access\_logging\_target\_bucket) | Optional: The name of the S3 bucket to use for access logging. If not provided, access logging will be disabled. | `string` | `null` | no |
| <a name="input_s3_bucket_access_logging_target_prefix"></a> [s3\_bucket\_access\_logging\_target\_prefix](#input\_s3\_bucket\_access\_logging\_target\_prefix) | Optional: The prefix to use for access logs. Defaults to 'log/'. | `string` | `"log/"` | no |
| <a name="input_s3_bucket_kms_key_arn"></a> [s3\_bucket\_kms\_key\_arn](#input\_s3\_bucket\_kms\_key\_arn) | Optional: The ARN of the KMS key to use for encrypting the S3 bucket. If not provided, AES256 encryption will be used. | `string` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Optional: The name of the S3 bucket to create. If not provided, a name will be generated. | `string` | `null` | no |
| <a name="input_s3_bucket_noncurrent_version_expiration_days"></a> [s3\_bucket\_noncurrent\_version\_expiration\_days](#input\_s3\_bucket\_noncurrent\_version\_expiration\_days) | Optional: The number of days to keep noncurrent object versions in the S3 bucket. Defaults to 30. | `number` | `30` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Cron expression for the Fargate task. | `string` | `"rate(15 minutes)"` | no |
| <a name="input_task_assign_public_ip"></a> [task\_assign\_public\_ip](#input\_task\_assign\_public\_ip) | Whether to assign a public IP to the Fargate task. Should be false for private subnets. | `bool` | `true` | no |
| <a name="input_task_image_tag"></a> [task\_image\_tag](#input\_task\_image\_tag) | Tag of the container image for the sync task. | `string` | `"latest"` | no |
| <a name="input_task_log_kms_key_id"></a> [task\_log\_kms\_key\_id](#input\_task\_log\_kms\_key\_id) | Optional: The ARN of the KMS key to use for encrypting the task's CloudWatch log group. | `string` | `null` | no |
| <a name="input_task_log_retention"></a> [task\_log\_retention](#input\_task\_log\_retention) | Optional: The task's CloudWatch log retention in days. | `number` | `30` | no |
| <a name="input_task_subnet_ids"></a> [task\_subnet\_ids](#input\_task\_subnet\_ids) | Optional: A list of subnet IDs to deploy the task into. Required if vpc\_id is set. | `list(string)` | `null` | no |
| <a name="input_task_vpc_id"></a> [task\_vpc\_id](#input\_task\_vpc\_id) | Optional: The ID of the VPC to deploy the task into. If null, uses the default VPC. | `string` | `null` | no |

## Outputs

No outputs.

<!-- prettier-ignore-end -->
<!-- END_TF_DOCS -->
