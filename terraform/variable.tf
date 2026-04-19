variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {
  default = "app-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ami_id" {
  description = "ami-0ec10929233384c7f"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
}


variable "desired_capacity" {
  default = 1
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 2
}



variable "region" {
  default = "us-east-1"
}

variable "repository_name" {
  default = "webapp"
}

variable "image_tag_mutability" {
  default = "MUTABLE"
}

variable "scan_on_push" {
  default = true
}

variable "encryption_type" {
  default = "AES256"
}
