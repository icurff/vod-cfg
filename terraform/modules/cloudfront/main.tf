terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.60"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# ── ACM Certificate (must be in us-east-1 for CloudFront) ──
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.frontend_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.frontend_domain}",
    var.api_domain,
    var.media_domain,
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# ── CloudFront Origin Access Control (OAC) for S3 ──
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "streamforge-s3-oac-${var.environment}"
  description                       = "OAC for StreamForge S3 media bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CloudFront Distribution: media.icurff.site → S3 (HLS streaming CDN) ──
resource "aws_cloudfront_distribution" "media" {
  comment             = "StreamForge Media CDN (${var.environment})"
  enabled             = true
  price_class         = "PriceClass_200" # Asia, US, Europe — cheapest with SEA coverage
  http_version        = "http2and3"
  wait_for_deployment = false

  aliases = var.enable_custom_domain ? [var.media_domain] : []

  origin {
    domain_name              = var.s3_bucket_regional_domain
    origin_id                = "s3-media-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # HLS manifest (.m3u8) — short TTL for live-like experience
  ordered_cache_behavior {
    path_pattern           = "*.m3u8"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-media-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = false
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 30

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
      headers = ["Origin"]
    }
  }

  # HLS segments (.ts) and other media — long TTL (immutable content)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-media-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 86400    # 1 day
    max_ttl                = 31536000 # 1 year (segments are immutable)

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
      headers = ["Origin"]
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate.cloudfront.arn : null
    cloudfront_default_certificate = var.enable_custom_domain ? false : true
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
  }

  tags = var.tags
}

# ── CloudFront Distribution: icurff.site → ALB → EKS (frontend) ──
resource "aws_cloudfront_distribution" "frontend" {
  comment             = "StreamForge Frontend CDN (${var.environment})"
  enabled             = true
  price_class         = "PriceClass_200"
  http_version        = "http2and3"
  wait_for_deployment = false

  aliases = var.enable_custom_domain ? [var.frontend_domain] : []

  origin {
    domain_name = var.alb_dns_name != "" ? var.alb_dns_name : "placeholder.example.com"
    origin_id   = "alb-frontend-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB listener is HTTP, CloudFront handles HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # API requests: no cache, pass through to origin
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-frontend-origin"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      cookies { forward = "all" }
      headers = ["*"]
    }
  }

  # Static assets: long cache
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-frontend-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
      headers = ["Host"]
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate.cloudfront.arn : null
    cloudfront_default_certificate = var.enable_custom_domain ? false : true
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
  }

  tags = var.tags
}
