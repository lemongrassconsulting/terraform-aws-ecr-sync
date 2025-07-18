# ecr-sync

<!-- BEGIN_TF_DOCS -->
<!-- prettier-ignore-start -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.eventbridge_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_config_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_execution_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eventbridge_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.eventbridge_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_config_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_s3_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_public_access_block.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.repo_defaults_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.s3_bucket_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnets.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for all resources. | `string` | n/a | yes |
| <a name="input_task_image_uri"></a> [task\_image\_uri](#input\_task\_image\_uri) | URI of the container image for the sync task. | `string` | n/a | yes |
| <a name="input_config"></a> [config](#input\_config) | A map defining the sync behavior, including mode, repositories and repo\_defaults. | <pre>object({<br/>    mode = optional(string, "create")<br/>    repos = optional(list(object({<br/>      source      = string<br/>      destination = optional(string)<br/>      tags        = list(string)<br/>    })), [])<br/>    repo_defaults = optional(object({<br/>      scan_on_push     = optional(bool, true)<br/>      tag_immutability = optional(bool, true)<br/>      encryption_type  = optional(string, "AES256")<br/>      kms_key_arn      = optional(string)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_s3_bucket_abort_incomplete_multipart_upload_days"></a> [s3\_bucket\_abort\_incomplete\_multipart\_upload\_days](#input\_s3\_bucket\_abort\_incomplete\_multipart\_upload\_days) | Optional: The number of days after which to abort incomplete multipart uploads. Defaults to 7. | `number` | `7` | no |
| <a name="input_s3_bucket_access_logging_target_bucket"></a> [s3\_bucket\_access\_logging\_target\_bucket](#input\_s3\_bucket\_access\_logging\_target\_bucket) | Optional: The name of the S3 bucket to use for access logging. If not provided, access logging will be disabled. | `string` | `null` | no |
| <a name="input_s3_bucket_access_logging_target_prefix"></a> [s3\_bucket\_access\_logging\_target\_prefix](#input\_s3\_bucket\_access\_logging\_target\_prefix) | Optional: The prefix to use for access logs. Defaults to 'log/'. | `string` | `"log/"` | no |
| <a name="input_s3_bucket_kms_key_arn"></a> [s3\_bucket\_kms\_key\_arn](#input\_s3\_bucket\_kms\_key\_arn) | Optional: The ARN of the KMS key to use for encrypting the S3 bucket. If not provided, AES256 encryption will be used. | `string` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Optional: The name of the S3 bucket to create. If not provided, a name will be generated. | `string` | `null` | no |
| <a name="input_s3_bucket_noncurrent_version_expiration_days"></a> [s3\_bucket\_noncurrent\_version\_expiration\_days](#input\_s3\_bucket\_noncurrent\_version\_expiration\_days) | Optional: The number of days to keep noncurrent object versions in the S3 bucket. Defaults to 30. | `number` | `30` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Cron expression for the Fargate task. | `string` | `"rate(15 minutes)"` | no |
| <a name="input_task_assign_public_ip"></a> [task\_assign\_public\_ip](#input\_task\_assign\_public\_ip) | Whether to assign a public IP to the Fargate task. Should be false for private subnets. | `bool` | `true` | no |
| <a name="input_task_ephemeral_storage_size"></a> [task\_ephemeral\_storage\_size](#input\_task\_ephemeral\_storage\_size) | Size of the ephemeral storage for the Fargate task in GiB. | `number` | `null` | no |
| <a name="input_task_image_tag"></a> [task\_image\_tag](#input\_task\_image\_tag) | Tag of the container image for the sync task. | `string` | `"latest"` | no |
| <a name="input_task_log_kms_key_id"></a> [task\_log\_kms\_key\_id](#input\_task\_log\_kms\_key\_id) | The ARN of the KMS key to use for encrypting the task's CloudWatch log group. Defaults to the AWS-managed key if null. | `string` | `null` | no |
| <a name="input_task_log_retention"></a> [task\_log\_retention](#input\_task\_log\_retention) | The task's CloudWatch log retention in days. | `number` | `30` | no |
| <a name="input_task_subnet_ids"></a> [task\_subnet\_ids](#input\_task\_subnet\_ids) | Optional: A list of subnet IDs to deploy the Fargate task into. Required if vpc\_id is provided. | `list(string)` | `null` | no |
| <a name="input_task_vpc_id"></a> [task\_vpc\_id](#input\_task\_vpc\_id) | Optional: The ID of the VPC to deploy the Fargate task into. If not provided, the default VPC is used. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the ECS cluster. |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | The ARN of the ECS task definition. |

<!-- prettier-ignore-end -->
<!-- END_TF_DOCS -->
