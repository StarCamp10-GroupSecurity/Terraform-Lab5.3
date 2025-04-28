output "domain_name" {
  description = "Domain Name for ALB"
  value       = try(module.lab.domain_name, null)
}