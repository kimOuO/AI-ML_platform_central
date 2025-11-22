#!/bin/bash

# =====================================================
# environmental variables for common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build ai_ml_oom-bds_connector :"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/topic-operation
export BACKEND_CONTAINER_NAME=aiml_bds_connector
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

docker rm -f ${BACKEND_CONTAINER_NAME}
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${BDS_CONNECTOR_CONTAINER_PORT}:8000 \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -itd ${BACKEND_IMAGE_NAME}:${BDS_CONNECTOR_API_VERSION} \
    bash ./shell/backend_init.sh

docker exec -it ${BACKEND_CONTAINER_NAME} bash -c "
    cp ${CONTAINER_WORKDIR}/.env.sample ${CONTAINER_WORKDIR}/.env
"

docker restart ${BACKEND_CONTAINER_NAME}

echo "##############################################################"
