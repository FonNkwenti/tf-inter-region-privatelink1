variable "main_region" {
  type    = string
  default = "us-east-1"
}

variable "transit_region" {
  type    = string
  default = "us-east-1"
}
variable "account_id" {
  type    = number
  default = 123456789012
}
variable "cross_account_id" {
  type    = number
  default = 123456789012
}


variable "privateLink_service_name" {
  type    = string
  default = ""
}

variable "environment" {
  description = "The environment for deployment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "cost_center" {
  description = "Cost center or budget code"
  type        = string
  default = "237"
}

variable "service_name" {
  description = "Type of application"
  type        = string
  default     = "web"
}


variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block of the VPC"
}

variable "ssh_key_pair" {
  type = string
  description = "name of existing SSH key pair"
  
}