# Ce fichier permettra d'afficher l'URL publique de ton site CloudFront une fois déployé.
output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "L'URL publique de ton site web via CloudFront"
}