variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "secondary_region" {
  type    = string
  default = "us-west-2"
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID for your domain"
  type        = string
}

variable "dns_record_name" {
  description = "DNS name to manage failover for, e.g. app.example.com"
  type        = string
}

variable "db_password" {
  description = "RDS master password. Pass via TF_VAR_db_password, not in a file."
  type        = string
  sensitive   = true
}
