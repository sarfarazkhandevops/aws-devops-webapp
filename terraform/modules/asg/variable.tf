variable "asg_name" { 
    type = string 
    }

variable "lt_name" { 
    
    type = string 
    }

variable "ami_id" {
     type = string 
     }

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_profile_name" {
  type = string
}

variable "instance_sg_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}


# ✅ NEW VARIABLES
variable "desired_capacity" {
  type    = number
}

variable "min_size" {
  type    = number
}

variable "max_size" {
  type    = number
}
