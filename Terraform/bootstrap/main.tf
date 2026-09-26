provider "aws" {
  region  = "ap-south-1"
  profile = "isak"
}

resource "aws_s3_bucket" "tf_state" {

    bucket = "manhumann-tf-bucket-state"

}

resource "aws_s3_bucket_versioning" "tf_state_version" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled" # Use "Suspended" to disable
  }
}

resource "aws_dynamodb_table" "tf_state_dynamo" {
  name         = "my-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "my-dynamodb-table"
  }
}   