variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Lambda function Trigger Docker Hub."
  type        = string
  default     = "dockerhub-webhook-trigger"
}

variable "target_endpoint_url" {
  description = "O URL do endpoint para o qual a Lambda fará a chamada GET."
  type        = string
  sensitive   = true # Marcar como sensível para não exibir em logs
}