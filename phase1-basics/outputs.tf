output "bucket_id" {
  description = "The name/ID of the S3 bucket"
  value       = aws_s3_bucket.learning.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.learning.arn
}

output "bucket_region" {
  description = "The AWS region where the bucket was created"
  value       = aws_s3_bucket.learning.region
}

output "bucket_domain_name" {
  description = "The bucket domain name (bucket-name.s3.amazonaws.com)"
  value       = aws_s3_bucket.learning.bucket_domain_name
}
