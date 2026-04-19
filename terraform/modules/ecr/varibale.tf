variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "image_tag_mutability" {
  description = "Mutable or Immutable"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "Lifecycle policy JSON"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags for ECR"
  type        = map(string)
  default     = {}
}
