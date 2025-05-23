// variables.tf
variable "vpc_id" {
  description = "VPC ID to deploy into"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ebs_volume_size" {
  description = "Root EBS volume size (GB)"
  type        = number
  default     = 8
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}