#!/usr/bin/env bash
# Live AWS test: scales the primary ASG to zero and waits for DNS to resolve
# to the supplied secondary ALB DNS name. This changes billable AWS resources.
# Usage: ./scripts/test_failover.sh <dns-name> <primary-asg-name> <secondary-alb-dns-name>
set -euo pipefail

DNS_NAME="${1:?Usage: test_failover.sh <dns-name> <primary-asg-name> <secondary-alb-dns-name>}"
ASG_NAME="${2:?Usage: test_failover.sh <dns-name> <primary-asg-name> <secondary-alb-dns-name>}"
SECONDARY_DNS="${3:?Usage: test_failover.sh <dns-name> <primary-asg-name> <secondary-alb-dns-name>}"

restore_primary() {
  echo "== Restoring primary region =="
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --min-size 1 --max-size 3 --desired-capacity 1
}
trap restore_primary EXIT INT TERM

echo "== Recording baseline resolution =="
dig +short "$DNS_NAME"
echo "== Simulating primary region outage: scaling $ASG_NAME to 0 =="
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --min-size 0 --max-size 0 --desired-capacity 0

START=$(date +%s)
echo "== Polling DNS every 10s for the secondary ALB: $SECONDARY_DNS =="
while true; do
  CURRENT=$(dig +short "$DNS_NAME" | head -n1)
  echo "$(date +%T)  resolves to: $CURRENT"
  if [[ "$CURRENT" == "$SECONDARY_DNS" ]]; then
    END=$(date +%s)
    echo "== Failover detected after $((END - START))s =="
    break
  fi
  sleep 10
done
