#!/bin/bash

set -eo pipefail

region="us-east-1"
# --query performs client-side response filtering. If there are too
# many instances, it's possible that instances that satisfy our
# criteria exist, but aren't returned in the first page of
# results. Currently, we only expect to get one page of results, but
# we will need to page through everything if that changes.
instances_raw="$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:Name,Values=Packer Builder")"
two_days_ago="$(date --date '-48 hours' '+%Y-%m-%dT%H')"
instances_jq_array="$(echo "${instances_raw}" | jq "[.Reservations | .[].Instances | .[]] | map(select(.LaunchTime < \"${two_days_ago}\"))")"
has_nonzero_instances="$(echo "${instances_jq_array}" | jq 'length > 0')"

if [ "${has_nonzero_instances}" != "true" ]; then
    echo "No instances to delete. Exiting."
    exit 0
fi

instance_ids="$(echo "${instances_jq_array}" | jq --raw-output '.[].InstanceId')"

printf "Deleting instances with the following ids:\n%s\n" "${instance_ids}"

echo "${instance_ids}" | xargs aws ec2 --region "${region}" terminate-instances --instance-ids
