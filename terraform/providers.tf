terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Route 53 is a global service but the Terraform AWS provider still needs
# one provider block to talk to it — using the primary alias is fine.
provider "aws" {
  region = var.primary_region
}
