#!/bin/bash

# =====================================================
# environmental variables for central-metadata_resource_mgt
# =====================================================
source ../Environmental_Variables/.env.postgres

# =====================================================
# environmental variables for common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build ai_ml_oom-metadata_mgt :"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/abstract-metadata_file-metadata
export BACKEND_CONTAINER_NAME=aiml_metadata_mgt
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

docker rm -f ${BACKEND_CONTAINER_NAME}
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${METADATA_MGT_CONTAINER_PORT}:8000 \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -itd ${BACKEND_IMAGE_NAME}:${METADATA_MGT_API_VERSION} \
    bash ./shell/backend_init.sh

docker exec -it "${BACKEND_CONTAINER_NAME}" bash -c "
  cp '${CONTAINER_WORKDIR}/.env.sample' '${CONTAINER_WORKDIR}/.env' && \
  sed -i \
    -e \"s|^HTTP_POSTGRES_DATABASE_NAME=.*|HTTP_POSTGRES_DATABASE_NAME=${METADATA_POSTGRES_DB}|\" \
    -e \"s|^HTTP_POSTGRES_PORT=.*|HTTP_POSTGRES_PORT=${METADATA_POSTGRES_CONTAINER_PORT}|\" \
    -e \"s|^HTTP_POSTGRES_USER=.*|HTTP_POSTGRES_USER=${METADATA_POSTGRES_USER}|\" \
    -e \"s|^HTTP_POSTGRES_PASSWORD=.*|HTTP_POSTGRES_PASSWORD=${METADATA_POSTGRES_PASSWORD}|\" \
    '${CONTAINER_WORKDIR}/.env'
"

docker restart ${BACKEND_CONTAINER_NAME}

echo "##############################################################"
