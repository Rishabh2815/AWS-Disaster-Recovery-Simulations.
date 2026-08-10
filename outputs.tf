output "primary_alb_dns_name" {
  value = module.compute_primary.alb_dns_name
}

output "secondary_alb_dns_name" {
  value = module.compute_secondary.alb_dns_name
}

output "route53_health_check_id" {
  value = module.dns_failover.health_check_id
}

output "db_primary_endpoint" {
  value = module.database_primary.endpoint
}

output "db_replica_endpoint" {
  value = module.database_secondary.endpoint
}
