variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_global_tables" {
  description = "Whether to enable global tables"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region for global table replica"
  type        = string
  default     = "us-west-2"
}

variable "kms_key_arn" {
  description = "KMS key ARN for replica table encryption"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}
