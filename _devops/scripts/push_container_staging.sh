#!/usr/bin/env bash
JQ_IMAGE="pinterb/jq:0.0.16"
FAMILY="cobrandingui-"
NEW_NGINX_IMAGE="${FAMILY}nginx"
LATEST_COMMIT=$(git rev-parse HEAD)
ENVIRONMENT="staging"
DEPLOY_NEW_REVISION=true
TRAEFIK_HOST="cobrandingui.stag.circusstreet.com"
LOG_GROUP="ECS-CobrandingUi-Staging"
DESIRED_CONTAINERS=1
DOCKERFILE_NAME="Dockerfile.ecs"

source _devops/scripts/_shared_push.sh
