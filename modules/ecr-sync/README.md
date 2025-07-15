# Terraform AWS ECR Pull-Sync Module

This repository contains a self-contained solution for replicating ECR images from a source account to a consumer account using a pull-based model.

It is a reusable Terraform Module that you can use to deploy the solution in your own AWS account. It deploys a companion Go application that runs in a Fargate task to perform the synchronization.
Container is available to customers on request.

---

## Architecture Overview

The solution works by deploying an AWS Fargate task into your (the consumer's) AWS account. This task runs on a schedule defined by an EventBridge cron job.

The containerized Go application uses the [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md) tool to perform the following steps:

1. **Fetch Configuration**: On startup, the Fargate task loads its configuration from an environment file stored in an S3 bucket. This file defines the sync mode, repositories, and tags to process.
2. **List Repositories**: It iterates through the repositories defined in the configuration.
3. **List Tags**: For each repository, it lists all available image tags.
4. **Filter and Copy**: It compares each tag against the user-defined filter patterns. For each match, it executes a `crane copy` command, which efficiently streams the image from the source to the destination ECR without needing to store it on disk.

This entire process is **pull-only** from the perspective of the source account. The task in your account initiates all connections, which is a security best practice. It only requires the source account to have a resource-based policy on its ECR repositories that grants your account pull access. No IAM roles or outbound connections are needed from the source account.

::: mermaid
graph TD
subgraph "Source AWS Account"
SourceECR[("Source ECR Repository")]
end

    subgraph "Your AWS Account (Consumer)"
        EventBridge(EventBridge Scheduler)
        FargateTask{"Fargate Task<br>(crane wrapper)"}
        DestinationECR[("Your ECR Repository")]
        S3Object[("S3 Object<br>.env Config")]

        EventBridge -->|Triggers on schedule| FargateTask
        FargateTask -->|Fetches config from| S3Object
    end

    FargateTask -->|PULLS image data via HTTPS| SourceECR
    FargateTask -->|PUSHES image data via HTTPS| DestinationECR

:::

---

## For Consumers: How to Use This Module

To use this solution, you only need to reference the Terraform module in your own infrastructure code. You can build the container yourself or point to a pre-built image that we provide.

### Prerequisites

- Terraform `~> 1.0`
- An existing ECR repository to pull the container image from.

### Usage

Here is an example of how to use the module in your Terraform code. For a complete, working example, see the `./basic-deployment` directory.

The module is called from your `main.tf`. You define input variables (typically in `variables.tf`) and provide their values in a `terraform.tfvars` or `*.auto.tfvars` file. The main configuration is passed via a single `config` object.

**`example.auto.tfvars`**

```hcl
# This file contains example configuration.
# Terraform automatically loads variables from files ending in .auto.tfvars.

# --- Required Configuration ---
namespace      = "example-ecr-sync"
task_image_uri = "111122223333.dkr.ecr.us-east-1.amazonaws.com/ecr-pull-sync" # Replace with your image URI

# --- Main Application Configuration ---
# This object defines the entire behavior of the sync application.
config = {
  mode = "create" # Can be "create" or "refresh"
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
    encryption_type  = "AES256" # Can be "AES256" or "KMS"
    # kms_key_arn      = "arn:aws:kms:us-east-1:111122223333:key/your-repo-kms-key-id"
  }
}
```

**`main.tf`**

```hcl
module "ecr_pull_sync" {
  # It is recommended to source the module from the Git repository directly,
  # pinning to a specific release tag for stability.
  source = "github.com/lcp-global/terraform-aws-ecr-sync?ref=v1.0.0"

  # --- Required ---
  namespace      = var.namespace
  task_image_uri = var.task_image_uri
  config         = var.config

  # --- Optional ---
  schedule       = var.schedule
  task_image_tag = var.task_image_tag
  # ... other variables can be passed here
}
```

### Configuration

#### Configuration (`config` variable)

You must provide a single configuration object that defines the entire sync behavior. This is typically done in a `.tfvars` file. The `config` object has the following structure:

- **`mode`** (Optional `string`): The sync mode. Defaults to `create`.
  - `create`: **(Default)** Ensures all repositories listed in `repos` exist in the destination and syncs all matching tags. It will create any missing repositories in your account.
  - `refresh`: Copies images only for repositories that **already exist** in your account. Use this if you manage repository creation through a separate IaC process.
- **`repos`** (Optional `list(object)`): A list of repository configurations to sync.
  - **`source`**: The full URI of the source repository (e.g., `111122223333.dkr.ecr.us-east-1.amazonaws.com/my-app/backend`). This field does **not** support glob patterns.
  - **`destination`** (Optional `string`): A custom name for the repository in the destination account. If omitted, the name is derived from the source path (e.g., `my-app/backend`).
  - **`tags`** (Optional `list(string)`): A list of glob patterns to filter which image tags are synced. If omitted, all tags (`**`) are synced.
- **`repo_defaults`** (Optional `object`): Default settings for any repositories created by the module when `mode` is `create`.
  - **`scan_on_push`** (Optional `bool`): Default setting for scanning images on push. Defaults to `true`.
  - **`tag_immutability`** (Optional `bool`): Default setting for tag immutability. Defaults to `true`.
  - **`encryption_type`** (Optional `string`): Default encryption type. Can be `AES256` or `KMS`. Defaults to `AES256`.
  - **`kms_key_arn`** (Optional `string`): The ARN of the KMS key to use if `encryption_type` is `KMS`.

**Glob Patterns for Tags:**

| Pattern       | Meaning                                                              |
| :------------ | :------------------------------------------------------------------- |
| `*`           | Matches any sequence of characters, but **not** a `/`.               |
| `**`          | Matches any sequence of characters, **including** a `/`.             |
| `?`           | Matches any single non-separator character.                          |
| `{alt1,alt2}` | Matches if any of the alternatives (e.g., `latest`, `stable`) match. |

**Evaluation Logic:**

1. The application iterates through the list of repositories defined in the `repos` block.
2. For each repository, it lists all available tags from the `source`.
3. It then filters this list of tags against the provided `tags` patterns.
4. Any tag matching at least one pattern will be synced.

**Example `config` object in a `.tfvars` file:**

```hcl
config = {
  # The top-level 'mode' can be 'create' or 'refresh'.
  mode = "create"

  # 'repos' is a list of source repositories to sync from.
  repos = [
    # Example 1: Sync all tags from a specific source repository.
    # The destination repository will be named 'my-app/backend'.
    {
      source = "111122223333.dkr.ecr.us-east-1.amazonaws.com/my-app/backend"
    },

    # Example 2: Sync only tags starting with 'v1.' for the 'gadgets/ui' repository.
    # Also, give it a custom name in our account.
    {
      source      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/gadgets/ui"
      destination = "my-team/ui-gadgets"
      tags        = ["v1.*"]
    },

    # Example 3: Sync only the 'latest' or 'stable' tag for the 'project/api' repo.
    {
      source = "111122223333.dkr.ecr.us-east-1.amazonaws.com/project/api"
      tags   = ["{latest,stable}"]
    },

    # Example 4: Sync tags that look like semantic versions for a shared library.
    {
      source = "111122223333.dkr.ecr.us-east-1.amazonaws.com/team-a/shared-library"
      tags = [
        "v?.?.?", # Matches v1.2.3, but not v1.2.34
        "v?.?"    # Matches v1.2, but not v1.23
      ]
    }
  ]

  # 'repo_defaults' defines default settings for any repositories created by this module.
  repo_defaults = {
    scan_on_push     = true
    tag_immutability = true
  }
}
```

### Private VPC Deployment

By default, this module attempts to deploy the Fargate task to the default VPC in your account. If you do not have a default VPC or wish to use a specific private VPC, you must provide the `task_vpc_id` and a list of `task_subnet_ids`.

**When using a private VPC, you are responsible for ensuring the necessary VPC endpoints are created and configured.** The Fargate task requires network access to the following AWS services:

- **ECR API**: `com.amazonaws.<region>.ecr.api` (Interface)
- **ECR DKR**: `com.amazonaws.<region>.ecr.dkr` (Interface)
- **S3**: `com.amazonaws.<region>.s3` (Gateway - required for S3 config and by ECR endpoints)
- **CloudWatch Logs**: `com.amazonaws.<region>.logs` (Interface)

**Example Configuration:**

```hcl
module "ecr_pull_sync" {
  source = "..."

  # ... other required variables ...

  # --- Private Networking ---
  task_vpc_id           = "vpc-0123456789abcdef0"
  task_subnet_ids       = ["subnet-0123456789abcdef0", "subnet-fedcba9876543210"]
  task_assign_public_ip = false
}
```
