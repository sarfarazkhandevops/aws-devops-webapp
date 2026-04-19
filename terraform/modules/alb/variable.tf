variable "alb_name" { type = string }
variable "tg_name" { type = string }

variable "vpc_id" { type = string }

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "target_port" {
  type    = number
  default = 80
}

variable "tags" {
  type    = map(string)
  default = {}
}