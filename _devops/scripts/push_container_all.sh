#!/usr/bin/env bash
JQ_IMAGE="pinterb/jq:0.0.16"
FAMILY="cobrandingui-"
NEW_NGINX_IMAGE="${FAMILY}nginx"
LATEST_COMMIT=$(git rev-parse HEAD)
ENVIRONMENT="production"
DEPLOY_NEW_REVISION=false
TRAEFIK_HOST="cobrandingui.circusstreet.com"
LOG_GROUP="ECS-CobrandingUi-Production"
DESIRED_CONTAINERS=1
DOCKERFILE_NAME="Dockerfile.ecs"

source _devops/scripts/_shared_push.sh
