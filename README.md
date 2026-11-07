# AWS Disaster Recovery Simulations

Terraform configuration and local simulation evidence for a warm-standby disaster recovery design across `us-east-1` (primary) and `us-west-2` (standby). **The infrastructure has not been applied to AWS.** The recorded RTO/RPO values come from a single local Docker/Lambda simulation and are not AWS measurements.

## Repository layout

```text
.
├── docs/assets/       Simulation report, architecture image, demo recording
├── scripts/           Explicitly opt-in live AWS failover test
├── terraform/         Root Terraform configuration
├── web/               Static observability dashboard
├── serve.ps1          Local dashboard server (PowerShell 7+)
└── README.md
```

> The root Terraform configuration references `../modules/network`, `compute`, `database`, and `dns-failover`. Those module directories are not included, so Terraform initialization/validation and deployment are currently blocked until the modules are added.

## Observability dashboard

The dashboard displays the documented simulation metrics, event timeline, region topology, phase breakdown, and repository evidence. It is static and deliberately labels data as simulation evidence; it does not connect to AWS or poll live resources.

On Windows with PowerShell 7+, from the repository root:

```powershell
./serve.ps1
```

Open <http://localhost:4173/>. Stop with `Ctrl+C`.

## Simulation evidence

- RTO: 135 seconds from failure injection to standby application database confirmation (one local run).
- RPO: last recorded replica write was one second before failure; no missing write was reported in that run.
- The 15-second health check, DNS, and promotion-wait phases and the 77-second promotion phase are listed in the source report. Whether each duration was configured or observed is not established in the repository.
- Real RDS replication lag, Route 53 behavior, and DNS resolver caching may differ. No AWS availability or recovery-time claim is made.

Artifacts: [`docs/assets/AWS dr failover results.pdf`](docs/assets/AWS%20dr%20failover%20results.pdf), [`docs/assets/aws_dr_project_architecture.png`](docs/assets/aws_dr_project_architecture.png), and [`docs/assets/terraform_dr_live_demo.mp4`](docs/assets/terraform_dr_live_demo.mp4).

## Terraform

Terraform root files are under `terraform/`. Once the referenced modules exist, configure required variables (`route53_zone_id`, `dns_record_name`, and sensitive `db_password`), then run:

```sh
cd terraform
terraform init
terraform validate
terraform plan
```

Do not run `terraform apply` unless you intend to create billable resources in both AWS regions and have reviewed the plan. Pass the database password as `TF_VAR_db_password`, not in a committed `.tfvars` file.

## Live failover script

`scripts/test_failover.sh` is a separate, opt-in AWS operation; it changes Auto Scaling capacity and needs AWS CLI credentials, `dig`, and the exact expected secondary ALB DNS name:

```sh
./scripts/test_failover.sh app.example.com primary-asg-name secondary-alb.example.com
```

Use only after deployment and review. The script restores the primary ASG on exit.
