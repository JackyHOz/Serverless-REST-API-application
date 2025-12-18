output "bucket_id" {
  value       = aws_s3_bucket.artifact.id
  description = "The ID of the artifact bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.artifact.arn
  description = "The ARN of the artifact bucket."
}
