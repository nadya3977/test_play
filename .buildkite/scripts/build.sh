#!/bin/bash
JSON_PATH="$(dirname $(realpath $0))/policy.json"

set -euo pipefail

if aws ecr describe-repositories --repository-names "${IMAGE_NAME}"; then
    echo "Repo ${IMAGE_NAME} already exists."
else
    echo "Creating ${IMAGE_NAME} repository."
    aws ecr create-repository --repository-name ${IMAGE_NAME}
fi

echo "Setting ECR policy for ${IMAGE_NAME}."

RESULT="$(aws ecr set-repository-policy --repository-name "${IMAGE_NAME}" --policy-text file://${JSON_PATH})"
echo "Successfully set policy."

docker build -t ${ACCOUNT_ID_BUILD}.dkr.ecr.ap-southeast-2.amazonaws.com/${IMAGE_NAME}:${IMAGE_VERSION:-latest} .
docker push ${ACCOUNT_ID_BUILD}.dkr.ecr.ap-southeast-2.amazonaws.com/${IMAGE_NAME}:${IMAGE_VERSION:-latest}

