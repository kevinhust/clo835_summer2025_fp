# CLO835 Final Project EKS Infrastructure

# Provider Configuration
provider "aws" {
  region = var.region
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "clo835_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "CLO835-FP-VPC"
    Environment                                 = var.environment
    Project                                     = var.project
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Public Subnet 1
resource "aws_subnet" "clo835_public_subnet_1" {
  vpc_id                  = aws_vpc.clo835_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "CLO835-FP-public-subnet-1"
    Environment                                 = var.environment
    Project                                     = var.project
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Public Subnet 2
resource "aws_subnet" "clo835_public_subnet_2" {
  vpc_id                  = aws_vpc.clo835_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "CLO835-FP-public-subnet-2"
    Environment                                 = var.environment
    Project                                     = var.project
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Private Subnet 1
resource "aws_subnet" "clo835_private_subnet_1" {
  vpc_id            = aws_vpc.clo835_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                        = "CLO835-FP-private-subnet-1"
    Environment                                 = var.environment
    Project                                     = var.project
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Private Subnet 2
resource "aws_subnet" "clo835_private_subnet_2" {
  vpc_id            = aws_vpc.clo835_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                        = "CLO835-FP-private-subnet-2"
    Environment                                 = var.environment
    Project                                     = var.project
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "clo835_igw" {
  vpc_id = aws_vpc.clo835_vpc.id

  tags = {
    Name        = "CLO835-FP-igw"
    Environment = var.environment
    Project     = var.project
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "clo835_nat_eip_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.clo835_igw]

  tags = {
    Name        = "CLO835-FP-nat-eip-1"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_eip" "clo835_nat_eip_2" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.clo835_igw]

  tags = {
    Name        = "CLO835-FP-nat-eip-2"
    Environment = var.environment
    Project     = var.project
  }
}

# NAT Gateway 1
resource "aws_nat_gateway" "clo835_nat_1" {
  allocation_id = aws_eip.clo835_nat_eip_1.id
  subnet_id     = aws_subnet.clo835_public_subnet_1.id
  depends_on    = [aws_internet_gateway.clo835_igw]

  tags = {
    Name        = "CLO835-FP-nat-gateway-1"
    Environment = var.environment
    Project     = var.project
  }
}

# NAT Gateway 2
resource "aws_nat_gateway" "clo835_nat_2" {
  allocation_id = aws_eip.clo835_nat_eip_2.id
  subnet_id     = aws_subnet.clo835_public_subnet_2.id
  depends_on    = [aws_internet_gateway.clo835_igw]

  tags = {
    Name        = "CLO835-FP-nat-gateway-2"
    Environment = var.environment
    Project     = var.project
  }
}

# Public Route Table
resource "aws_route_table" "clo835_public_rt" {
  vpc_id = aws_vpc.clo835_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clo835_igw.id
  }

  tags = {
    Name        = "CLO835-FP-public-rt"
    Environment = var.environment
    Project     = var.project
  }
}

# Private Route Table 1
resource "aws_route_table" "clo835_private_rt_1" {
  vpc_id = aws_vpc.clo835_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.clo835_nat_1.id
  }

  tags = {
    Name        = "CLO835-FP-private-rt-1"
    Environment = var.environment
    Project     = var.project
  }
}

# Private Route Table 2
resource "aws_route_table" "clo835_private_rt_2" {
  vpc_id = aws_vpc.clo835_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.clo835_nat_2.id
  }

  tags = {
    Name        = "CLO835-FP-private-rt-2"
    Environment = var.environment
    Project     = var.project
  }
}

# Route Table Associations
resource "aws_route_table_association" "clo835_public_rta_1" {
  subnet_id      = aws_subnet.clo835_public_subnet_1.id
  route_table_id = aws_route_table.clo835_public_rt.id
}

resource "aws_route_table_association" "clo835_public_rta_2" {
  subnet_id      = aws_subnet.clo835_public_subnet_2.id
  route_table_id = aws_route_table.clo835_public_rt.id
}

resource "aws_route_table_association" "clo835_private_rta_1" {
  subnet_id      = aws_subnet.clo835_private_subnet_1.id
  route_table_id = aws_route_table.clo835_private_rt_1.id
}

resource "aws_route_table_association" "clo835_private_rta_2" {
  subnet_id      = aws_subnet.clo835_private_subnet_2.id
  route_table_id = aws_route_table.clo835_private_rt_2.id
}

# Security Group for EKS Cluster
resource "aws_security_group" "clo835_eks_cluster_sg" {
  name        = "CLO835-FP-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.clo835_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "CLO835-FP-eks-cluster-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# Security Group for EKS Nodes
resource "aws_security_group" "clo835_eks_node_sg" {
  name        = "CLO835-FP-eks-node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.clo835_vpc.id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "Cluster to node communication"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.clo835_eks_cluster_sg.id]
  }

  ingress {
    description     = "Cluster API to node kubelets"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.clo835_eks_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "CLO835-FP-eks-node-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "clo835_eks_cluster_role" {
  name = "CLO835-FP-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "CLO835-FP-eks-cluster-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "clo835_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clo835_eks_cluster_role.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "clo835_eks_node_role" {
  name = "CLO835-FP-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "CLO835-FP-eks-node-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach required policies to EKS node role
resource "aws_iam_role_policy_attachment" "clo835_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.clo835_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "clo835_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.clo835_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "clo835_eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.clo835_eks_node_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "clo835_eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.clo835_eks_cluster_role.arn
  version  = "1.30"

  vpc_config {
    security_group_ids = [aws_security_group.clo835_eks_cluster_sg.id]
    subnet_ids = [
      aws_subnet.clo835_private_subnet_1.id,
      aws_subnet.clo835_private_subnet_2.id,
      aws_subnet.clo835_public_subnet_1.id,
      aws_subnet.clo835_public_subnet_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.clo835_eks_cluster_policy,
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project
  }
}

# OIDC Identity Provider for EKS
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.clo835_eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.clo835_eks.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.cluster_name}-oidc"
    Environment = var.environment
    Project     = var.project
  }
}

# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "AmazonEKS_EBS_CSI_DriverRole"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach EBS CSI policy
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.clo835_eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.46.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.clo835_nodes,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]

  tags = {
    Name        = "${var.cluster_name}-ebs-csi"
    Environment = var.environment
    Project     = var.project
  }
}

# EKS Node Group
resource "aws_eks_node_group" "clo835_nodes" {
  cluster_name    = aws_eks_cluster.clo835_eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.clo835_eks_node_role.arn
  subnet_ids = [
    aws_subnet.clo835_private_subnet_1.id,
    aws_subnet.clo835_private_subnet_2.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.clo835_eks_worker_node_policy,
    aws_iam_role_policy_attachment.clo835_eks_cni_policy,
    aws_iam_role_policy_attachment.clo835_eks_container_registry_policy,
  ]

  tags = {
    Name        = var.node_group_name
    Environment = var.environment
    Project     = var.project
  }
}

# S3 Bucket for Background Images
resource "aws_s3_bucket" "clo835_background_images" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
    Project     = var.project
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "clo835_background_images_versioning" {
  bucket = aws_s3_bucket.clo835_background_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "clo835_background_images_encryption" {
  bucket = aws_s3_bucket.clo835_background_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "clo835_background_images_pab" {
  bucket = aws_s3_bucket.clo835_background_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ECR Repository
resource "aws_ecr_repository" "clo835_webapp" {
  name                 = "clo835fp-${var.ecr_repository_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "clo835fp-${var.ecr_repository_name}"
    Environment = var.environment
    Project     = var.project
  }
}

# ECR Repository Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "clo835_webapp_lifecycle" {
  repository = aws_ecr_repository.clo835_webapp.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Application S3 Access IAM Role
resource "aws_iam_role" "app_s3_role" {
  name = "LabRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:fp:clo835-sa"
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "LabRole"
    Environment = var.environment
    Project     = var.project
  }
}

# S3 Access Policy for Application
resource "aws_iam_policy" "s3_background_images_access" {
  name        = "S3BackgroundImagesAccess"
  description = "IAM policy for S3 background images access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.clo835_background_images.arn,
          "${aws_s3_bucket.clo835_background_images.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "S3BackgroundImagesAccess"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach S3 policy to application role
resource "aws_iam_role_policy_attachment" "app_s3_policy" {
  policy_arn = aws_iam_policy.s3_background_images_access.arn
  role       = aws_iam_role.app_s3_role.name
}

# Attach ECR read-only policy to application role
resource "aws_iam_role_policy_attachment" "app_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.app_s3_role.name
}