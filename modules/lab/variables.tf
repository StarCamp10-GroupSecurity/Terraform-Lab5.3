#####################
#     REGION        #
#####################
variable "region" {
  description = "Region"
  type        = string
  default     = "us-east-1"
}

#####################
#        ENV        #
#####################

variable "environment" {
  description = "Environment VPC"
  type        = string
  default     = "Production"
}

#####################
#        VPC        #
#####################

variable "proj" {
  description = "Name of the VPC"
  type        = string
  default     = "Cyber DevOps Lab 4.1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

#####################
#        EC2        #
#####################

variable "ec2_instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.medium"
}

variable "my_ami_id" {
  description = "AMI Id"
  type        = string
  default     = null
}