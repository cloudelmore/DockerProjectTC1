variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "tc1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "frontend_port" {
  description = "Port the frontend container listens on"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "CPU units per task (512 = 0.5 vCPU)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory per task in MiB (1024 = 1 GB)"
  type        = number
  default     = 1024
}

variable "min_tasks" {
  description = "Minimum number of tasks per service"
  type        = number
  default     = 1
}

variable "desired_tasks" {
  description = "Desired number of tasks per service at creation"
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum number of tasks per service"
  type        = number
  default     = 4
}

variable "cpu_target_percent" {
  description = "Average CPU utilization that triggers auto scaling"
  type        = number
  default     = 50
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in this region, used for SSH to Jenkins"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form (for example 203.0.113.10/32), allowed to SSH to Jenkins"
  type        = string
}
