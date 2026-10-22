output "vpc_id" {
  description = "The ID of the newly constructed network VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of created public subnet IDs inside the VPC."
  value       = aws_subnet.public[*].id
}

output "iam_role_arns" {
  description = "ARNs of compliance IAM Roles mapped by environment names."
  value       = { for env, role in aws_iam_role.sai_roles : env => role.arn }
}

output "ec2_instance_id" {
  description = "The unique tracking ID of the Sai-DevOps EC2 instance."
  value       = aws_instance.sai_devops.id
}

output "ec2_instance_public_ip" {
  description = "The assigned public IPv4 address of the Sai-DevOps instance."
  value       = aws_instance.sai_devops.public_ip
}
