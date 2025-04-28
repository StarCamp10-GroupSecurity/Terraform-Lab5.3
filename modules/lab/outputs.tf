# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = try(aws_vpc.main.id, null)
# }

output "domain_name" {
  description = "Domain Name for ALB"
  value       = try(aws_alb.main.dns_name, null)
}
