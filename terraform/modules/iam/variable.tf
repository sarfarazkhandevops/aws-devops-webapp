variable "role_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "attach_cloudwatch" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}