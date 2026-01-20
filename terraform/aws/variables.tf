variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "fastapi-microservices"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner du projet"
  type        = string
  default     = "tiffany"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}
