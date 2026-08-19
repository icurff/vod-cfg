output "oac_id" { value = aws_cloudfront_origin_access_control.s3_oac.id }
output "media_distribution_arn" { value = aws_cloudfront_distribution.media.arn }
output "media_distribution_domain" { value = aws_cloudfront_distribution.media.domain_name }
output "media_distribution_id" { value = aws_cloudfront_distribution.media.id }
output "frontend_distribution_domain" { value = aws_cloudfront_distribution.frontend.domain_name }
output "acm_certificate_arn" { value = aws_acm_certificate.cloudfront.arn }
output "acm_validation_records" {
  value       = aws_acm_certificate.cloudfront.domain_validation_options
  description = "Add these DNS CNAME records to validate the ACM certificate"
}
