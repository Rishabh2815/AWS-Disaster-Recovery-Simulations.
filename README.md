# AWS-Disaster-Recovery-Simulations.

# AWS Disaster Recovery Simulation

A two-region warm-standby architecture on AWS with automated Route 53
failover routing, provisioned entirely through modular Terraform.

## Status — read this first

**This is complete, correct Terraform that has not yet been applied to a
real AWS account.** I wrote and hand-reviewed every module, but I have not
run `terraform apply`, stood up the actual infrastructure, or measured a
real failover time. 

What's true right now: the architecture is real and deployable, the
Terraform is modular and follows AWS best practices for warm standby, and
`scripts/test_failover.sh` is a real test you can run once it's deployed.
What's not true yet: any specific failover time, cost figure, or "it
works" claim — those only become honest once you've run it.

## Architecture

```
                    Route 53 (health-checked failover routing)
                         │
            ┌────────────┴────────────┐
            │                         │
      PRIMARY (us-east-1)      SECONDARY (us-west-2)
            │                         │
    ┌───────┴───────┐         ┌───────┴───────┐
    │  ALB + ASG    │         │  ALB + ASG     │  ← warm: min 1 instance
    │  (app tier)   │         │  (app tier)    │     running, not cold
    └───────┬───────┘         └───────┬───────┘
            │                         │
    ┌───────┴───────┐         ┌───────┴───────┐
    │  RDS primary  │────────▶│  RDS read      │
    │               │ replic. │  replica       │
    └───────────────┘         └───────────────┘
```

Route 53 continuously health-checks the primary region's load balancer. If
it fails health checks, Route 53 stops resolving the DNS record to the
primary and starts resolving to the secondary — automatically, with no
manual DNS change required. The secondary region runs a small standing
fleet (not zero instances) and a continuously-replicating RDS read replica,
so failover means "promote and redirect traffic," not "provision from
scratch," which is what makes this a *warm* standby rather than cold.

## Why warm standby (and not pilot light or hot/hot)

- **Cold/pilot light** — cheaper, but recovery means booting infrastructure
  from scratch, which costs minutes to tens of minutes and risks
  configuration drift between "what's defined" and "what actually boots."
- **Hot/hot (active-active)** — fastest failover, but doubles steady-state
  cost and requires solving multi-region write conflicts, which is a much
  bigger problem than this project needs to solve to make the point.
- **Warm standby** — a small always-on fleet plus a continuously replicating
  database gets you fast, low-drama failover without full active-active
  cost or complexity. It's the right trade-off for a portfolio project
  demonstrating DR concepts without needing production-scale traffic.

## Repo structure

```
aws-dr-sim/
  modules/
    network/         VPC, public/private subnets, NAT, routing — per region
    compute/          ALB + Auto Scaling Group + launch template
    database/         RDS primary (or cross-region read replica)
    dns-failover/     Route 53 health check + PRIMARY/SECONDARY failover records
  scripts/
    test_failover.sh  Scales primary ASG to 0 and times DNS failover
  main.tf              Wires two regions together via provider aliases
  variables.tf
  outputs.tf
  providers.tf
  terraform.tfvars.example
```

## Deploying it

Prerequisites: an AWS account, Terraform ≥1.5, an existing Route 53 hosted
zone for a domain you control (failover routing needs a real zone).

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your route53_zone_id and dns_record_name

export TF_VAR_db_password="something-strong-not-committed"

terraform init
terraform validate
terraform plan     # review carefully — this creates billable resources
terraform apply
```

**Cost warning:** this creates two NAT gateways, two ALBs, EC2 instances,
and two RDS instances (one primary, one replica) — this is not free-tier
and will accrue real cost per hour it's running. Destroy it when you're
done testing:

```bash
terraform destroy
```

## Testing failover

Once deployed, get your ASG name and DNS record, then:

```bash
./scripts/test_failover.sh app.yourdomain.com primary-asg <secondary-alb-ip-or-cname>
```

This scales the primary ASG to zero (simulating an outage), polls DNS
until it resolves to the secondary region, and prints the elapsed time.
**This elapsed time — not an estimate — is the number that belongs on a
resume**, once you've actually run it.

## Known gaps / what I'd add with more time

- No automated RDS promotion — the read replica needs to be manually
  promoted to a standalone writable primary during a real failover; this
  isn't scripted yet.
- No application-level connection string handling for the failover case
  (the app tier would need to know to point at the promoted replica).
- No cost monitoring/alerting on the standing secondary fleet.
- Terraform hasn't been run against a real account yet — see Status above.
