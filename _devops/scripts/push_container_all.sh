#!/usr/bin/env bash

JQ_IMAGE="pinterb/jq:0.0.16"
LATEST_COMMIT=$(git rev-parse HEAD)
DEPLOY_NEW_REVISION=false
LOG_GROUP="ECS-Datadog-agent"
DESIRED_CONTAINERS=1


# Build the datadog-agent container
aws ecr get-login --region eu-west-1 --no-include-email | sh
#
docker build -t datadog-agent -f Dockerfile-ecs .
docker tag datadog-agent:latest 533639970857.dkr.ecr.eu-west-1.amazonaws.com/datadog-agent:latest

# Push the containers to ECR
docker push 533639970857.dkr.ecr.eu-west-1.amazonaws.com/datadog-agent:latest

read -d '' -r CREATE_TASK_JSON << EOF
{
    "family": "datadog-agent-task",
    "networkMode": "bridge",
    "taskRoleArn": "arn:aws:iam::533639970857:role/ecs_datadog_agent",
    "containerDefinitions": [
        {
            "name": "datadog-agent",
            "image": "533639970857.dkr.ecr.eu-west-1.amazonaws.com/datadog-agent:latest",
            "memoryReservation": 256,
            "cpu": 10,
            
            
            "mountPoints": [
              {
                "containerPath": "/var/run/docker.sock",
                "sourceVolume": "docker_sock",
                "readOnly": true
              },
              {
                "containerPath": "/host/sys/fs/cgroup",
                "sourceVolume": "cgroup",
                "readOnly": true
              },
              {
                "containerPath": "/host/proc",
                "sourceVolume": "proc",
                "readOnly": true
              }
            ],            
            "environment": [
              {
                "name": "DD_API_KEY",
                "value": "8d5c8c6d234611e10bd856e414ee0324"
              },
              {
          	    "name": "SD_BACKEND",
        	    "value": "docker"
              }
            ],
            "volumes": [
              {
                "host": {
                  "sourcePath": "/var/run/docker.sock"
                },
                "name": "docker_sock"
              },
              {
                "host": {
                  "sourcePath": "/proc/"
                },
                "name": "proc"
              },
              {
                "host": {
                   "sourcePath": "/cgroup/"
                },
                "name": "cgroup"
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
                    "awslogs-stream-prefix": "datadog--"
                }
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
	echo "# Updating ECS service datadog-agent with task revision ${NEW_REVISION_NUMBER}"
	echo "################################################################################"
	echo
	echo

	### note cobranding-ui in service name is a hardcoded hack to account for service name mismatch to $FAMILLY variable
    read -d '' -r UPDATE_SERVICE_JSON << EOF
{
    "cluster": "sugar69-ecs",
    "service": "datadog-agent",
    "desiredCount": ${DESIRED_CONTAINERS},
    "taskDefinition": "datadog-agent:${NEW_REVISION_NUMBER}"
}
EOF
    aws ecs update-service --region eu-west-1 --cli-input-json "$UPDATE_SERVICE_JSON" #&> /dev/null
    if [ $? -eq 1 ]; then
        echo "Failed to update ECS service"
        exit 1
    fi
fi

echo ${NEW_REVISION_NUMBER}
