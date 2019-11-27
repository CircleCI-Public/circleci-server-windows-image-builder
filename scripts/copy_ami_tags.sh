#!/bin/bash
set -eo pipefail

FROM_REGION=$1
FROM_AMI=$2
TO_REGION=$3
TO_AMI=$4

TAGS="$(aws ec2 describe-images --region "${FROM_REGION}" --image-ids "${FROM_AMI}" | jq --raw-output '.Images[0].Tags | map("Key=\(.Key),Value=\(.Value)") | join(" ")')"

echo "Copying tags ${TAGS} from ${FROM_AMI} to ${TO_AMI}"

echo "${TAGS}" | xargs aws ec2 create-tags --region "${TO_REGION}" --resources "${TO_AMI}" --tags
