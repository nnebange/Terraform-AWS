#Step 3 - Creates S3 backend
terraform {
  backend "s3" {
    #Replace this with your bucket name!
    bucket = "terraform-hiba-state-v.1"
    key    = "dc/s3/terraform.tfstate"
    region = "us-east-1"
    #Replace this with your DynamoDB table name!
    dynamodb_table = "tf-hiba-state-locks-v.1"
    encrypt        = true
  }
}