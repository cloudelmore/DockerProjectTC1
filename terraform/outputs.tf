output "frontend_url" {
  description = "Public URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "jenkins_url" {
  description = "Jenkins web UI"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_ssh" {
  description = "SSH command for the Jenkins server"
  value       = "ssh -i <path-to-${var.key_name}.pem> ec2-user@${aws_eip.jenkins.public_ip}"
}

output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "frontend_service_name" {
  value = aws_ecs_service.frontend.name
}

output "backend_service_name" {
  value = aws_ecs_service.backend.name
}
