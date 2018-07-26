#!/usr/bin/env bash

# Build the Nginx container
docker build -t ${NEW_NGINX_IMAGE} -f ${DOCKERFILE_NAME} .
docker tag ${NEW_NGINX_IMAGE}:latest 533639970857.dkr.ecr.eu-west-1.amazonaws.com/${NEW_NGINX_IMAGE}:latest-${ENVIRONMENT}

# Push the containers to ECR
aws ecr get-login --region eu-west-1 --no-include-email | sh
docker push 533639970857.dkr.ecr.eu-west-1.amazonaws.com/${NEW_NGINX_IMAGE}:latest-${ENVIRONMENT}

read -d '' -r CREATE_TASK_JSON << EOF
{
    "family": "${FAMILY}${ENVIRONMENT}",
    "networkMode": "bridge",
    "taskRoleArn": "arn:aws:iam::533639970857:role/ecs_app_cobrandingui",
    "containerDefinitions": [
        {
            "name": "nginx",
            "image": "533639970857.dkr.ecr.eu-west-1.amazonaws.com/${NEW_NGINX_IMAGE}:latest-${ENVIRONMENT}",
            "memoryReservation": 128,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "disableNetworking": false,
            "privileged": false,
            "readonlyRootFilesystem": false,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "${LOG_GROUP}",
                    "awslogs-region": "eu-west-1",
                    "awslogs-stream-prefix": "Nginx--"
                }
            },
            "dockerLabels": {
                "traefik.enable": "true",
                "traefik.backend": "nginx",
                "traefik.frontend.rule": "Host:${TRAEFIK_HOST}",
                "traefik.frontend.priority": "6",
                "traefik.frontend.passHostHeader": "true",
                "traefik.frontend.entryPoints": "http"
            }
        }
    ]
}
EOF

rm -f register-task-definition-failure
CREATE_TASK_REVISION=$(aws ecs register-task-definition --region eu-west-1 --cli-input-json "$CREATE_TASK_JSON" 2> register-task-definition-failure)
if [ -z "$CREATE_TASK_REVISION" ]; then
    echo "Failed to create a new ECS task revision"
    cat register-task-definition-failure
    exit 1
fi

if [[ "$(docker images -q ${JQ_IMAGE} 2> /dev/null)" == "" ]]; then
  docker pull ${JQ_IMAGE} > /dev/null
  if [ $? -eq 1 ]; then
    echo "Failed to pull ${JQ_IMAGE}"
    exit 1
  fi
fi

NEW_REVISION_NUMBER=$(echo "${CREATE_TASK_REVISION}" | docker run -i ${JQ_IMAGE} '.taskDefinition.revision' | xargs echo -n)

if [ "$DEPLOY_NEW_REVISION" = true ]; then
	echo
	echo
	echo "################################################################################"
	echo "# Updating ECS service cobranding-ui\"${ENVIRONMENT}\" with task revision ${NEW_REVISION_NUMBER}"
	echo "################################################################################"
	echo
	echo

	### note cobranding-ui in service name is a hardcoded hack to account for service name mismatch to $FAMILLY variable
    read -d '' -r UPDATE_SERVICE_JSON << EOF
{
    "cluster": "circusstreet",
    "service": "cobranding-ui-${ENVIRONMENT}",
    "desiredCount": ${DESIRED_CONTAINERS},
    "taskDefinition": "cobrandingui-${ENVIRONMENT}:${NEW_REVISION_NUMBER}"
}
EOF
    aws ecs update-service --region eu-west-1 --cli-input-json "$UPDATE_SERVICE_JSON" &> /dev/null
    if [ $? -eq 1 ]; then
        echo "Failed to update ECS service"
        exit 1
    fi
fi

echo ${NEW_REVISION_NUMBER}
