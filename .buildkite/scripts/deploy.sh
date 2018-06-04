#!/bin/bash
BASE_DIR="$(dirname $(realpath $0))"
DOCKER_DEPLOY_ECS=${DOCKER_DEPLOY_ECS:-local/ecs-cli}
IMAGE_VERSION="${IMAGE_VERSION:-latest}"

if [ -z "${TRAEFIK_ENVIRONMENT}" ]; then
    echo "Missing environment variavle TRAEFIK_ENVIRONMENT, exiting."
    exit 1
fi
if [ -z "${ECS_CLUSTER_NAME}" ]; then
    echo "Missing environment variavle ECS_CLUSTER_NAME, exiting."
    exit 1
fi
 
function load_role() {
    export AWS_ACCESS_KEY_ID=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_access_key_id/) print $2}' ~/.aws/credentials | tr -d ' ')
    export AWS_SECRET_ACCESS_KEY=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_secret_access_key/) print $2}' ~/.aws/credentials | tr -d ' ')
    export AWS_SESSION_TOKEN=$(awk -F '=' '{if (! ($0 ~ /^;/) && $0 ~ /aws_session_token/) print $2}' ~/.aws/credentials | tr -d ' ')
}

function assume_role() {
    echo "+++ :aws: Configure CodeCommit credentials helper | Assume AMI build role"

    echo "Assume role: arn:aws:iam::${TARGET_ACCOUNT_ID}:role/${TARGET_ACCOUNT_ROLE}"
    temp_role=$(aws sts assume-role \
                        --role-arn "arn:aws:iam::${TARGET_ACCOUNT_ID}:role/${TARGET_ACCOUNT_ROLE}" \
                        --role-session-name "docker-ecs-deploy-${IMAGE_NAME}")

    export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
    export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
    export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)
}

if [ -z "${CI}" ]; then
    load_role
else
    assume_role
fi

ECS_CLI="docker run -e AWS_ACCESS_KEY_ID \
                    -e AWS_SECRET_ACCESS_KEY \
                    -e AWS_SESSION_TOKEN \
                    -e ACCOUNT_ID_BUILD \
                    -e TRAEFIK_ENVIRONMENT \
                    --env-file=${BASE_DIR}/deploy.env \
                    -v ${BASE_DIR}:/app \
                    ${DOCKER_DEPLOY_ECS} \
                    compose \
                    --project-name ${IMAGE_NAME} \
                    -c ${ECS_CLUSTER_NAME}"

echo "::: Creating service if it doesn't already exist."
${ECS_CLI} service create || true

echo "Deploying task."
${ECS_CLI} service up