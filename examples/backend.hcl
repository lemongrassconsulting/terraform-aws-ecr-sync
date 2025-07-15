# Example S3 backend configuration
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "prod/ecr-pull-sync/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "your-terraform-lock-table"
#   }
# }
