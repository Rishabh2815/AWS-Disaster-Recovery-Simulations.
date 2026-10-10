# AWS Multi-Region Disaster Recovery

A Terraform-defined warm-standby disaster recovery design across two AWS regions (us-east-1 primary, us-west-2 standby), using RDS cross-region read replicas and Route 53 failover routing. The failover behaviour was evaluated in a **local Docker and Lambda simulation**, not on AWS.

## Evidence

- **Simulation results report (PDF):** [`docs/AWS_dr_failover_results.pdf`](docs/AWS_dr_failover_results.pdf) `<FILL: confirm path>`

## Deployment status

| Item | Status |
|---|---|
| Deployed to AWS | **No** |
| AWS resources created | **None** |
| `terraform apply` run | **No** |
| `terraform validate` / `terraform plan` run | `<FILL: Yes/No>` |
| Failover tested on real AWS infrastructure | **No** |

The Terraform code is written but has never been applied to an AWS account (cost). Every result in this README comes from a local simulation. No figure here is an AWS measurement.

## Architecture

| Terraform module | Purpose |
|---|---|
| `network` | VPC and networking in both regions |
| `compute` | Application tier in both regions (standby sized for warm standby) |
| `database` | RDS primary plus cross-region read replica |
| `dns-failover` | Route 53 health check and failover routing records |

**Strategy:** warm standby. The standby region runs a scaled-down stack with a continuously replicated database. On failure, the replica is promoted and traffic is routed to the standby.

---

## Failover evaluation (local Docker and Lambda simulation)

> **This is a simulation.** The primary and standby "regions", the database replication, the health check, the DNS switch and the promotion were all modelled locally with Docker containers and Lambda. The timings describe the simulated failover sequence, not the speed of Route 53, RDS or any AWS service. One run (n = 1).

### Simulation environment

| Item | Value |
|---|---|
| Host | `<FILL: machine, OS>` |
| Runtime | Docker (`<FILL: Docker version, Compose file>`) |
| Lambda | `<FILL: what the Lambda function does and how it was run locally, e.g. Lambda runtime image or SAM local>` |
| Simulated primary / standby | `<FILL: containers used for each>` |
| Simulated database replication | `<FILL: mechanism, e.g. Postgres streaming replication between two containers>` |
| Simulated health check | `<FILL: what polls what, interval and failure threshold>` |
| Simulated DNS switch | `<FILL: mechanism, TTL modelled as 60 s>` |
| Failure injection | `<FILL: what was stopped or blocked in the simulation>` |
| Write load | `<FILL: tool, write rate>` |
| Replication lag | <100 ms (`<FILL: how it was measured>`) |
| Runs | 1 |
| Date of run | `<FILL>` |

### Which delays were measured and which were configured

This matters for how the RTO should be read. Fill in each row:

| Phase | Duration in run | Produced by |
|---|---|---|
| Health check detection | 15 s | `<FILL: emerged from interval x threshold in the simulation / configured delay>` |
| DNS update / client cache expiry | 15 s | `<FILL: emerged from modelled TTL / configured delay>` |
| Waiting for the promotion command | 15 s | `<FILL: manual delay / script delay>` |
| Replica promotion | 77 s | `<FILL: real promotion time in the containers / injected delay modelled on RDS>` |
| Standby app confirms DB connectivity | 13 s | `<FILL>` |

If a phase is an injected or modelled delay, the RTO is partly an input to the simulation, not an observation. Say so in this table.

### Timeline (UTC, simulated)

| Event | Time | Offset from failure |
|---|---|---|
| Simulation started | 14:32:10 | |
| Write load started | 14:33:45 | |
| **Failure injected** | **14:38:20** | **0 s** |
| Simulated health check flips unhealthy | 14:38:35 | +15 s |
| Simulated DNS update, clients retry against standby | 14:38:50 | +30 s |
| Replica promotion issued | 14:39:05 | +45 s |
| Replica promotion complete | 14:40:22 | +122 s |
| Standby app confirms DB connectivity | 14:40:35 | +135 s |
| Teardown complete | 14:41:50 | |

### RTO

**Definition:** time from failure injection (`t0` = 14:38:20) to the standby application confirming database connectivity (`t1` = 14:40:35).

**Result: 135 seconds in the simulation** (one run): 15 s detection + 15 s DNS + 15 s waiting for promotion + 77 s promotion + 13 s app recovery.

### RPO

**Definition:** the gap between failure injection and the last write present on the promoted replica, plus a check for acknowledged writes missing after promotion.

**Result:** the last write on the promoted replica was at 14:38:19, 1 s before the failure, and no write was found missing (one run).

This reflects the simulated replication setup and the write interval of the load generator. Real RDS cross-region read replicas replicate asynchronously, so a real RPO can be higher and depends on actual replication lag.

### What this does and does not show

- It shows the failover orchestration (detect, promote, redirect, verify) works end to end in the simulation.
- It does not give AWS timings. A real failover would additionally include Route 53 health check detection (Route 53 supports 10 s or 30 s check intervals), DNS TTL and resolver caching, actual RDS replica promotion time, and real cross-region replication lag.
- It is a single run, with a manual promotion step, a small data set and no real regional outage.

---

## Roadmap (not implemented)

- Apply the Terraform to a real account for a short, torn-down test run and measure real RTO and RPO.
- Automate promotion (for example an EventBridge or SNS-triggered Lambda) to remove the manual delay.
- Repeat the simulation and report min / median / max, not a single run.
- Add fault-injection cases (network partition, instance crash, AZ outage).

## Repository layout and setup

`<FILL: real tree and the commands that work from a fresh clone, including how to run the Docker and Lambda simulation>`

```bash
cd <FILL: terraform directory>
terraform init
terraform validate
# terraform apply is NOT run for this project; it would create billable resources in two regions
```








