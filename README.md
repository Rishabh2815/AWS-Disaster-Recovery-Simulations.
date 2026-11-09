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

The dashboard displays the documented simulation metrics, event timeline, region topology, phase breakdown, and repository evidence. Replay the recorded event sequence at 1×, 4×, or 8×, pause or reset it, filter events by category, and export the event log as CSV. The playback is an interactive view of the recorded run; it does not run a new failover, connect to AWS, or poll live resources. All figures remain labeled as simulation evidence.

To publish a public dashboard URL, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions**. The included workflow deploys the dashboard when files under `web/` change on `main`.

On Windows with PowerShell 7+, double-click `start-dashboard.cmd` to start the server and open the dashboard in your default browser. Or run this from the repository root:

```powershell
./serve.ps1
```

Open <http://localhost:4174/>. Keep the console window open while using the dashboard; stop the server with `Ctrl+C`.

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
