variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources."
  default     = "eu-central-1"
}

variable "environments" {
  type        = list(string)
  description = "List of target environments for operational roles."
  default     = ["dev", "QA", "Ops"]
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the custom VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Subnet allocations within the VPC."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "service_permissions" {
  type        = map(list(string))
  description = "Mapping of target services to their precise allowed IAM actions."
  default = {
    cloudwatch = [
      "cloudwatch:PutMetricData", 
      "cloudwatch:DescribeAlarms", 
      "cloudwatch:GetMetricStatistics"
    ]
    ssm = [
      "ssm:GetParameter", 
      "ssm:GetParameters", 
      "ssm:DescribeInstanceInformation"
    ]
    sns = [
      "sns:Publish", 
      "sns:ListTopics"
    ]
    dynamodb = [
      "dynamodb:GetItem", 
      "dynamodb:PutItem", 
      "dynamodb:Scan", 
      "dynamodb:Query"
    ]
  }
}
