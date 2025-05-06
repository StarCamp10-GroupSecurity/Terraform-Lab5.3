provider "aws" {
  region  = "us-east-1"


  assume_role {
    role_arn = "arn:aws:iam::891377265038:role/lab53_role"
  }
}