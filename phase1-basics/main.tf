# Random suffix to ensure globally unique S3 bucket names
# S3 bucket names are global across ALL AWS accounts — this prevents conflicts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket — Phase 1 learning resource
resource "aws_s3_bucket" "learning" {
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}
