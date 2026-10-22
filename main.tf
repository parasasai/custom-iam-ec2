terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# -----------------------------------------------------------------------------
# STEP 1: STATE STORE HOUSE ARCHITECTURE (S3 Remote Storage Target)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state_bucket" {
  bucket        = "sai-devops-remote-state-bucket"
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "state_bucket_oc" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket_public_block" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# LOCALS & EXPRESSIONS MAPPING
# -----------------------------------------------------------------------------
locals {
  # Mandated syntax: ec2role-yourname (e.g., ec2role-dev-Sai, ec2role-QA-Sai, ec2role-Ops-Sai)
  role_names = { for env in var.environments : env => "ec2role-${env}-Sai" }

  # Generate policy structure mapping wildcard explicitly at the Resource block only
  policy_statements = [
    for service, actions in var.service_permissions : {
      Effect   = "Allow"
      Action   = actions
      Resource = ["*"]
    }
  ]
}

# -----------------------------------------------------------------------------
# NETWORK LAYER INFRASTRUCTURE (VPC, Subnets, IGW, Route Tables)
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "Sai-VPC"
    ManagedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "Sai-IGW"
    ManagedBy = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "Sai-PublicSubnet-${count.index + 1}"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "Sai-PublicRouteTable"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# IAM ROLE & PROFILES CONFIGURATION
# -----------------------------------------------------------------------------
resource "aws_iam_role" "sai_roles" {
  for_each = local.role_names

  name = each.value

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = each.value
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "sai_role_policies" {
  for_each = local.role_names

  name = "${each.value}-multi-service-policy"
  role = aws_iam_role.sai_roles[each.key].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policy_statements
  })
}

resource "aws_iam_instance_profile" "sai_profiles" {
  for_each = local.role_names
  name     = "${each.value}-profile"
  role     = aws_iam_role.sai_roles[each.key].name
}

# -----------------------------------------------------------------------------
# COMPUTE SECURITY GROUP
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "Sai-EC2-SG"
  description = "Basic outbound connectivity for DevOps instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "Sai-EC2-SecurityGroup"
    ManagedBy = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE (Sai-DevOps)
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "sai_devops" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  iam_instance_profile   = aws_iam_instance_profile.sai_profiles["dev"].name

  tags = {
    Name      = "Sai-DevOps"
    ManagedBy = "Terraform"
  }
}
