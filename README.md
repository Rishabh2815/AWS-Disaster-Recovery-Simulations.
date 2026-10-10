
# AWS Multi-Region Disaster Recovery Architecture

A Terraform-defined warm-standby disaster recovery design across two AWS regions, using RDS cross-region read replicas and Route 53 health-checked failover routing.

## Deployment status

| Item | Status |
|---|---|
| Terraform code written | Yes |
| `terraform apply` run against a live AWS account | **No** |
| AWS resources created | **None** |
| `terraform validate` / `terraform plan` run | `<FILL: Yes/No, and against which account or mock>` |
| Failover tested on real AWS infrastructure | **No** |

**This project has not been deployed to AWS.** It was not applied because of cost. Everything described below as "tested" refers to a local simulation, not to AWS services. Behaviour on real AWS, including timings, is unverified.

---

## Architecture

| Terraform module | Purpose |
|---|---|
| `network` | VPC and networking in the primary and standby regions |
| `compute` | Application tier in both regions (standby sized for warm standby) |
| `database` | RDS primary plus cross-region read replica |
| `dns-failover` | Route 53 health check and failover routing records |

**Strategy:** warm standby. The standby region runs a scaled-down copy of the stack with a continuously replicated database. On failure, the replica is promoted and traffic is routed to the standby.

Regions: `<FILL: primary>` and `<FILL: standby>`.

---

## Failover evaluation (local / simulated)

> **This evaluation was run locally. It is a simulation of the failover logic, not a measurement of AWS.** The RTO and RPO values below must not be quoted as AWS performance.

### Environment

| Item | Value |
|---|---|
| Host | `<FILL: machine, OS>` |
| Simulation tooling | `<FILL: Docker Compose, LocalStack, scripts, etc.>` |
| "Primary" database | `<FILL: e.g. Postgres container>` |
| "Replica" database | `<FILL: e.g. Postgres container with streaming replication>` |
| Replication mode | `<FILL: sync / async, and any artificial lag injected>` |
| "Health check" and "DNS" stand-in | `<FILL: e.g. script polling /health, proxy that switches upstream>` |
| Failure injected | `<FILL: e.g. docker stop primary-app and primary-db>` |
| Number of runs | `<FILL>` |

### Definitions

- **RTO (recovery time objective, measured):** time from failure injection (`t0`) until the first successful request served by the standby (`t1`). `RTO = t1 - t0`.
- **RPO (recovery point objective, measured):** the amount of acknowledged data lost at failover. Measured as the count of writes acknowledged by the primary that are missing on the promoted replica, and the time span they cover.

### Measurement procedure

1. Start a client loop that sends a request every `<FILL: interval>` and logs a timestamp, HTTP status and which site answered.
2. Start a writer loop that inserts rows with a sequence number and wall-clock timestamp, and logs each sequence number only after the primary acknowledges it.
3. Record `t0` and inject the failure.
4. Promote the replica (`<FILL: how: command or script>`) and switch traffic.
5. Record `t1` as the timestamp of the first successful response from the standby.
6. After promotion, compare the writer log with the promoted database:
   - `lost_writes = acknowledged sequence numbers not present on the replica`
   - `RPO window = timestamp of last acknowledged write - timestamp of last surviving write`
7. Repeat for `<FILL>` runs and report min / median / max, not a single number.

Scripts: `<FILL: path to scripts, committed to repo>`. Raw logs: `<FILL: path>`.

### Results (simulated)

| Run | RTO (s) | Lost writes | RPO window (s) |
|---|---|---|---|
| 1 | `<FILL>` | `<FILL>` | `<FILL>` |
| 2 | `<FILL>` | `<FILL>` | `<FILL>` |
| 3 | `<FILL>` | `<FILL>` | `<FILL>` |
| **Median** | `<FILL>` | `<FILL>` | `<FILL>` |

### What these numbers do and do not show

They show that the failover sequence (detect, promote, redirect) works in the simulated setup and how long that sequence takes there.

They do **not** include delays that exist on real AWS and were not measured:

- Route 53 health check detection time (check interval multiplied by failure threshold)
- DNS TTL and client resolver caching
- RDS cross-region replica promotion time
- Real cross-region replication lag, which determines true RPO for an asynchronous replica

A real RTO would be at least the sum of these plus application warm-up time. Treat the simulated figures as a lower bound on the logic, not a prediction for AWS.

---

## Limitations

- Not deployed; no AWS-measured RTO or RPO exists.
- Simulated replication lag is `<FILL: injected value or none>`, so the RPO result reflects that setting only.
- Cost, IAM and cross-region data transfer behaviour are untested.
- `<FILL: other gaps>`

## Using the Terraform

```bash
cd terraform
terraform init
terraform validate
# terraform plan   # requires AWS credentials; creates nothing
# terraform apply  # NOT run for this project
```

Applying this configuration to a real account will create billable resources, including an RDS instance and replica in two regions.
