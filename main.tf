# 1. Création du Bucket S3 (privé)
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name
}

# type de bloc puis type de ressource puis nom de la variable
# resource = on veut créer un objet sur le cloud
# aws_s3_bucket un type de ressource (chez AWS)
# website_bucket nom de la variable dans le code local
# Ici on init le bucket et on lui set un nom récupérer depuis le variables.tf (l'env)

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.website_bucket.id
# Ces 2 params empêchent l'utilisation d'anciennes méthodes de partage public (les ACLs).
  block_public_acls       = true
  ignore_public_acls      = true
# Ces 2 ci bloquent toute tentative future d'écrire une règle qui rendrait le bucket publiquement accessible à tout Internet.
  block_public_policy     = true
  restrict_public_buckets = true
}

# ici on veut editer le s3 créé précédemment pour le config (ici changer la sécurité)

# 2. Upload automatique des fichiers du dossier www/
resource "aws_s3_object" "website_files" {
  for_each     = fileset("${path.module}/www", "**/*") # boucle sur tous les fichiers du dossier www pour écrire sur le S3
  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.value # le nom et le chemin du fichier dans le bucket S3
  source       = "${path.module}/www/${each.value}" # le chemin du fichier sur le disque local
  etag         = filemd5("${path.module}/www/${each.value}") # check si un fichier a changé pour le re-uploader
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream") # check le type de fichier (MIME TYPE) pour le set dans le S3 sinon par defaut application/octet-stream
}

# Mapping simple pour détecter le type MIME des fichiers (html, css, js)
locals  {
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
  }
}

# 3. CloudFront Origin Access Control (OAC) pour sécuriser l'accès au S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-${var.bucket_name}"
  description                       = "OAC pour sécuriser l'accès au S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"  # Indication de toujours signer les requetes faites au s3
  signing_protocol                  = "sigv4" # Signer les requetes avec le protocole sigv4 (AWS Signature Version 4)
}

# 4. Politique de compartiment S3 (on whitlist uniquement CloudFront via l'OAC)
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

# 5. Distribution CloudFront (On setup CloudFront reverse proxy)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}