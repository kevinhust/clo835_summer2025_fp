# Outputs for CLO835 Final Project EKS Infrastructure

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.clo835_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.clo835_public_subnet_1.id, aws_subnet.clo835_public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [aws_subnet.clo835_private_subnet_1.id, aws_subnet.clo835_private_subnet_2.id]
}

output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.clo835_eks.id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.clo835_eks.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.clo835_eks.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.clo835_eks.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.clo835_eks.arn
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.clo835_eks.certificate_authority[0].data
}

output "eks_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.clo835_nodes.arn
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.clo835_webapp.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.clo835_webapp.arn
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for background images"
  value       = aws_s3_bucket.clo835_background_images.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.clo835_background_images.arn
}

output "s3_bucket_region" {
  description = "The region of the S3 bucket"
  value       = aws_s3_bucket.clo835_background_images.region
}