# Remote State Backend — AWS S3 + DynamoDB
# State is encrypted at rest via S3 SSE-AES256.
# State locking via DynamoDB table.
#
# Bootstrap (run once before terraform init):
#   aws s3 mb s3://streamforge-tfstate-393698973321 --region ap-southeast-1
#   aws s3api put-bucket-versioning --bucket streamforge-tfstate-393698973321 --versioning-configuration Status=Enabled
#   aws dynamodb create-table --table-name streamforge-tfstate-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST --region ap-southeast-1

terraform {
  backend "s3" {
    bucket       = "streamforge-tfstate-393698973321"
    key          = "streamforge/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
