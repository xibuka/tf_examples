variable "access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
}
variable "secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}

variable "region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "ap-northeast-1"
}

variable "private_key_path" {
  type        = string
  description = "path to ssh private key"
}

variable "public_key_path" {
  type        = string
  description = "path to ssh pub key"
}
