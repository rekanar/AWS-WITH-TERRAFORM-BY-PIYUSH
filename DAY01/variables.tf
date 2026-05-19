variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "tf-learning"
}

variable "bucket_suffix" {
  description = "Unique suffix for the S3 bucket name to ensure global uniqueness"
  type        = string
  default     = "day01"
}
