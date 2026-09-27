output "public_ips" {
  value = { for i in aws_instance.final_project_instances : i.tags.Name => i.public_ip }
}

output "public_dns" {
  value = { for i in aws_instance.final_project_instances : i.tags.Name => i.public_dns }
}

output "jenkins_deploy_private_key" {
  value     = tls_private_key.jenkins_deploy.private_key_openssh
  sensitive = true
}

output "jenkins_deploy_public_key" {
  value = tls_private_key.jenkins_deploy.public_key_openssh
}
