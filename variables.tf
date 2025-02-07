variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "snowflake_stage_ref" {
  description = "Snowflake stage reference"
  type        = string
  default     = "@DDS.PUBLIC.HACK_THE_FUTURE_DATA_STAGE"
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "prod.therealfriends.de"
}

