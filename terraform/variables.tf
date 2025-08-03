# Variables for CLO835 Final Project EKS Infrastructure

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for the first private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "clo835-eks-cluster"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "clo835-eks-nodes"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.small"
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for background images"
  type        = string
  default     = "clo835fp-background-images"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project tag"
  type        = string
  default     = "CLO835-FinalProject"
}