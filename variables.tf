# Ce fichier définit les variables personnalisables, comme la région AWS et le nom de ton compartiment S3 (qui doit être mondialement unique)

variable "aws_region" {
  type        = string
  default     = "eu-north-1"
  description = "La région AWS pour déployer les ressources"
}

variable "bucket_name" {
  type        = string
  description = "Nom unique pour le compartiment S3"
}