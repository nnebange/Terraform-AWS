# ---- Networking / variables.tf -------

variable "vpc_cidr" {
  type = string
}

variable "public_cidrs" {
  type = list(any)
}

# Private Cidrs

variable "private_cidrs" {
  type = list(any)
}

#Private Subnet Count

variable "public_sn_count" {
  type = number
}

#Private Subnet Count

variable "private_sn_count" {
  type = number
}

# Max subnets
variable "max_subnets" {
  type = number
}

variable "access_ip" {
  type = string
}

variable "security_groups" {}

variable "db_subnet_group" {
  type = bool
}