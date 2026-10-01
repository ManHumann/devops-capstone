variable "name" {
  description = "Name of the Security group"
  type        = string
}

variable "description" {
  description = "Description of the Security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID is SG"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules for the security group"

  type = map(object({
    description                  = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))

  default = {}

}

variable "egress_rules" {
  description = "Egress rules for the security group"

  type = map(object({
    description = string
    from_port   = optional(number)
    to_port     = optional(number)
    ip_protocol = string
    cidr_ipv4   = optional(string)
  }))

  default = {}

}