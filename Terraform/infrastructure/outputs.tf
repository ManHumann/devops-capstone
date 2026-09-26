output "public_ips" {
  value = { for i in aws_instance.final_project_instances : i.tags.Name => i.public_ip }
}

output "public_dns" {
  value = { for i in aws_instance.final_project_instances : i.tags.Name => i.public_dns }
}