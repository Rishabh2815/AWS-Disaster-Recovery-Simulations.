# ---------- PRIMARY REGION ----------

module "network_primary" {
  source      = "./modules/network"
  providers   = { aws = aws.primary }
  region      = var.primary_region
  name_prefix = "primary"
}

module "compute_primary" {
  source             = "./modules/compute"
  providers          = { aws = aws.primary }
  name_prefix        = "primary"
  vpc_id             = module.network_primary.vpc_id
  public_subnet_ids  = module.network_primary.public_subnet_ids
  private_subnet_ids = module.network_primary.private_subnet_ids
}

module "database_primary" {
  source             = "./modules/database"
  providers          = { aws = aws.primary }
  name_prefix        = "primary"
  vpc_id             = module.network_primary.vpc_id
  private_subnet_ids = module.network_primary.private_subnet_ids
  password           = var.db_password
  is_replica         = false
}

# ---------- SECONDARY (DR) REGION ----------

module "network_secondary" {
  source      = "./modules/network"
  providers   = { aws = aws.secondary }
  region      = var.secondary_region
  name_prefix = "secondary"
}

module "compute_secondary" {
  source             = "./modules/compute"
  providers          = { aws = aws.secondary }
  name_prefix        = "secondary"
  vpc_id             = module.network_secondary.vpc_id
  public_subnet_ids  = module.network_secondary.public_subnet_ids
  private_subnet_ids = module.network_secondary.private_subnet_ids
  # Warm standby: keep a small but running fleet, not zero, so failover
  # is "promote and repoint DNS," not "boot everything from scratch."
  desired_capacity = 1
  min_size         = 1
}

module "database_secondary" {
  source               = "./modules/database"
  providers            = { aws = aws.secondary }
  name_prefix          = "secondary"
  vpc_id               = module.network_secondary.vpc_id
  private_subnet_ids   = module.network_secondary.private_subnet_ids
  password             = var.db_password
  is_replica           = true
  replicate_source_db  = module.database_primary.instance_arn
}

# ---------- DNS FAILOVER ----------

module "dns_failover" {
  source                  = "./modules/dns-failover"
  zone_id                 = var.route53_zone_id
  record_name             = var.dns_record_name
  primary_alb_dns_name    = module.compute_primary.alb_dns_name
  primary_alb_zone_id     = module.compute_primary.alb_zone_id
  secondary_alb_dns_name  = module.compute_secondary.alb_dns_name
  secondary_alb_zone_id   = module.compute_secondary.alb_zone_id
}
