#!/usr/bin/env bash
# Failover test: scales the primary region's ASG to zero (simulating an
# outage) and polls the DNS record to time how long Route 53 takes to
# start resolving to the secondary region instead.
#
# Usage: ./scripts/test_failover.sh app.yourdomain.com primary-asg-name

set -euo pipefail

DNS_NAME="${1:?Usage: test_failover.sh <dns-name> <primary-asg-name>}"
ASG_NAME="${2:?Usage: test_failover.sh <dns-name> <primary-asg-name>}"

echo "== Recording baseline resolution =="
dig +short "$DNS_NAME"

echo "== Simulating primary region outage: scaling $ASG_NAME to 0 =="
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --min-size 0 --max-size 0 --desired-capacity 0

START=$(date +%s)
echo "== Polling DNS every 10s until it resolves to the secondary ALB =="

while true; do
  CURRENT=$(dig +short "$DNS_NAME" | head -n1)
  echo "$(date +%T)  resolves to: $CURRENT"
  # Replace this with your actual secondary ALB IP/CNAME check once deployed
  if [[ "$CURRENT" != "$3" ]]; then
    END=$(date +%s)
    echo "== Failover detected after $((END - START))s =="
    break
  fi
  sleep 10
done

echo "== Restoring primary region =="
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --min-size 1 --max-size 3 --desired-capacity 1
