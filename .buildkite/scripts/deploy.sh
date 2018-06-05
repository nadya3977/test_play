#!/bin/bash
BASE_DIR="$(dirname $(realpath $0))"
DOCKER_DEPLOY_ECS="${DOCKER_DEPLOY_ECS:-local/ecs-cli}"
ECS_DESIRED_COUNT="${ECS_DESIRED_COUNT:-1}"

if [ -z "${TRAEFIK_ENVIRONMENT}" ]; then
    echo "Missing environment variable TRAEFIK_ENVIRONMENT, exiting."
    exit 1
fi
if [ -z "${ECS_CLUSTER_NAME}" ]; then
    echo "Missing environment variable ECS_CLUSTER_NAME, exiting."
    exit 1
fi
if [ -z "${IMAGE_NAME}" ]; then
    echo "Missing environment variable IMAGE_NAME, exiting."
    exit 1
fi
if [ -z "${IMAGE_VERSION}" ]; then
    echo "Missing environment variable IMAGE_VERSION, exiting."
    exit 1
fi
 
function load_role() {
    export AWS_ACCESS_KEY_ID=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_access_key_id/) print $2}' ~/.aws/credentials | tr -d ' ')
    export AWS_SECRET_ACCESS_KEY=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_secret_access_key/) print $2}' ~/.aws/credentials | tr -d ' ')
    export AWS_SESSION_TOKEN=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_session_token/) print $2}' ~/.aws/credentials | tr -d ' ')
}

if [ -z "${CI}" ]; then
    load_role
fi

set -euo pipefail

ECS_CLI="docker run -e AWS_ACCESS_KEY_ID \
                    -e AWS_SECRET_ACCESS_KEY \
                    -e AWS_SESSION_TOKEN \
                    -e ACCOUNT_ID_BUILD \
                    -e TRAEFIK_ENVIRONMENT \
                    -e IMAGE_NAME \
                    -e IMAGE_VERSION \
                    --env-file=${BASE_DIR}/deploy.env \
                    -v ${BASE_DIR}:/app \
                    ${DOCKER_DEPLOY_ECS} \
                    compose \
                    --project-name ${ECS_TASK_NAME} \
                    -c ${ECS_CLUSTER_NAME}"

echo "::: Creating service if it doesn't already exist. Will fail with false error if service already exists."
${ECS_CLI} service create || true

echo "::: Deploying task."
${ECS_CLI} service up

echo "::: Scaling task to ${ECS_DESIRED_COUNT} instances."
${ECS_CLI} service scale "${ECS_DESIRED_COUNT}"