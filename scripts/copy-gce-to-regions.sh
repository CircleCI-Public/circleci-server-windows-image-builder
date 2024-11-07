#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_IF_CHANGED="$1"
readonly JOB_NAME="$2"
readonly MONOREPO_CONTENT_SHA="$(./scripts/get_content_sha "${BUILD_IF_CHANGED}")"
readonly FROM_REGION="us"
readonly IMAGE_CMD=(./google-cloud-sdk/bin/gcloud --quiet beta compute images)
readonly REGIONS=("us-east1" "us-central1")
readonly IMAGE_NAME="$(./scripts/get_last_image googlecompute "${MONOREPO_CONTENT_SHA}" "${JOB_NAME}" "${FROM_REGION}")"

wait_for_image_to_be_ready () {
    local status="PENDING"
    local attempts=0
    echo "Waiting for image to reach READY status"
    while [[ "$attempts" -le 300 && "$status" != "READY" ]]; do
        echo -n "."
        status=$("${IMAGE_CMD[@]}" describe "${IMAGE_NAME}" --format json | jq -r '.status')
        ((attempts++)) || true
        sleep 1
    done
    if [[ "$status" != "READY" ]]; then
        echo "Image never became ready: '${IMAGE_NAME}' status is '${status}' after '${attempts}' attempts"
        exit 1
    fi
    echo
}

copy_to_region () {
    local dest_region="$1"
    local labels
    local new_image

    if new_image=$(./scripts/get_last_image googlecompute "${MONOREPO_CONTENT_SHA}" "${JOB_NAME}" "${dest_region}"); then
        echo "Already exists: '${new_image}'"
        return
    fi
    local new_image_name="${IMAGE_NAME}-${dest_region}"
    labels=$("${IMAGE_CMD[@]}" describe "${IMAGE_NAME}" --format json | jq -r '.labels | to_entries | map("\(.key)=\(.value)") | join(",")')
    "${IMAGE_CMD[@]}" --no-user-output-enabled create \
        "${new_image_name}" \
        --labels="${labels},region=${dest_region}" \
        --source-image "${IMAGE_NAME}" \
        --storage-location "${dest_region}"
    echo "Copied to: '${new_image_name}'"
}

wait_for_image_to_be_ready

echo "Copying from source image '${IMAGE_NAME}'"
for region in "${REGIONS[@]}"; do
    copy_to_region "${region}"
done