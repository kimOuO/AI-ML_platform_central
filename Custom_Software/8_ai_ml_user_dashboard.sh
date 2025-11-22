#!/bin/bash

# =====================================================
# environmental variables for user-dashboard
# =====================================================
source ../Environmental_Variables/.env.central-dashboard

# =====================================================
# environmental variables for common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build central-dashboard :"
echo ""

export FRONTEND_IMAGE_NAME=140.118.162.95/prod/ai-ml-user-dashboard
export FRONTEND_CONTAINER_NAME=ai_ml_user_dashboard
export CONTAINER_WORKDIR=/app

docker rm -f ${FRONTEND_CONTAINER_NAME}
docker run \
    --restart=always \
    --name ${FRONTEND_CONTAINER_NAME} \
    -p ${AIML_USER_DASHBOARD_CONTAINER_PORT}:${FRONTEND_INTERNAL_CONTAINER_PORT} \
    -v ${PWD}/../Environmental_Variables/.env.central-dashboard:${CONTAINER_WORKDIR}/.env \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -itd ${FRONTEND_IMAGE_NAME}:${AIML_USER_DASHBOARD_API_VERSION} \

docker exec -it ${FRONTEND_CONTAINER_NAME} bash -c "
    source .env && \
    source .env.common && \
    source .env && \
    export $(cut -d= -f1 .env) && \
    npm run build
"

docker restart ${FRONTEND_CONTAINER_NAME}

sleep 3

docker exec -itd ${FRONTEND_CONTAINER_NAME} bash -c "npm start"
echo "##############################################################"
