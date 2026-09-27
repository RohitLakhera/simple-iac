variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for naming and tagging"
  type        = string
  default     = "devops-iac"
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of web servers"
  type        = number
  default     = 2
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH. Lock this down to your Jenkins server IP/32 in real use!"
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_key" {
  description = "SSH public key content for the EC2 key pair (injected by Jenkins as TF_VAR_public_key)"
  type        = string
}
