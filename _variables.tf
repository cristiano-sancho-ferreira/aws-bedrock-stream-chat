variable "region_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}
