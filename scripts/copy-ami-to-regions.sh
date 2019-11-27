#!/bin/bash

BUILD_IF_CHANGED=$1
JOB_NAME=$2
FROM_REGION=$3
MONOREPO_CONTENT_SHA="$(./scripts/get_content_sha "${BUILD_IF_CHANGED}")"

copy_to_region () {
    AMI_ID=$1
    FROM_REGION=$2
    DEST_REGION=$3
    AMI_NAME=$4

    if ./scripts/get_last_image amazon-ebs "${MONOREPO_CONTENT_SHA}" "${JOB_NAME}" "${DEST_REGION}"; then
        echo "Image with monorepo_content_sha ${MONOREPO_CONTENT_SHA}, circle_job_name ${JOB_NAME} already exists in ${DEST_REGION}. Not copying."
    else
        NEW_AMI_ID=$(aws ec2 copy-image --name "${AMI_NAME}" --source-region "${FROM_REGION}" --region "${DEST_REGION}" --source-image-id "${AMI_ID}" | jq -r '.ImageId')
        if [[ -z "$NEW_AMI_ID" ]]
        then
            echo "Failed to initiate copying of image: $AMI_ID"
            exit 1
        fi

        echo "Copying image: $AMI_ID to region: $DEST_REGION. New image AMI_ID: $NEW_AMI_ID"

        state="pending" #Possible image states (available | pending | failed ) from AWS docs.
        echo "New image $NEW_AMI_ID in $state state. Starting status poll(every 20s)"
        sleep 5s # Sleep for 5 sec before polling
        max_cycle_count=30 # = 10min with 20s sleep inside the loop
        cycle=0
        while [[ $state == "pending" ]] && [[ cycle -lt max_cycle_count ]]
        do
            state=$(aws ec2 describe-images --region "${DEST_REGION}" --image-ids "${NEW_AMI_ID}" | jq -r '.Images[0].State')
            echo "Waiting for AMI_ID: $NEW_AMI_ID in region: $DEST_REGION..."
            sleep 20s
            cycle=$((cycle + 1))
        done

        if [[ $state != "available" ]]
        then
            echo "Failed copying image to region: $DEST_REGION with new AMI_ID: $NEW_AMI_ID"
            exit 1
        fi
        echo "Successfully copied image to region: $DEST_REGION with new AMI_ID: $NEW_AMI_ID"
        echo "Making $NEW_AMI_ID public..."
        aws ec2 modify-image-attribute --region $DEST_REGION --image-id $NEW_AMI_ID --launch-permission "Add=[{Group=all}]"
        echo "Tagging $NEW_AMI_ID"
        ./scripts/copy_ami_tags.sh "${FROM_REGION}" "${AMI_ID}" "${DEST_REGION}" "${NEW_AMI_ID}"
    fi
}

AMI_ID="$(./scripts/get_last_image amazon-ebs ${MONOREPO_CONTENT_SHA} ${JOB_NAME} ${FROM_REGION})"
export AMI_ID


AMI_NAME=$(aws ec2 describe-images --region $FROM_REGION --image-ids $AMI_ID | jq -r '.Images[0].Name')

if [[ -z "$AMI_NAME" ]]
    then
        echo "Failed to get image name for AMI_ID: $AMI_ID"
        exit 1
fi
regions=("us-east-2"
         "us-west-1"
         "us-west-2"
         "ap-northeast-1"
         "ap-northeast-2"
         "ap-south-1"
         "ap-southeast-1"
         "ap-southeast-2"
         "ca-central-1"
         "eu-central-1"
         "eu-west-1"
         "eu-west-2"
         "sa-east-1")

for DEST_REGION in ${regions[@]}; do
  copy_to_region $AMI_ID $FROM_REGION $DEST_REGION $AMI_NAME &
  sleep 1s
done

wait
echo "Finished copying to regions"
