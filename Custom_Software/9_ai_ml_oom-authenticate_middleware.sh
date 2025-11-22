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
echo "Build ai_ml_oom-authenticate_middleware :"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/entrypoint
export BACKEND_CONTAINER_NAME=aiml_authenticate_middleware
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

docker rm -f ${BACKEND_CONTAINER_NAME}
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${AUTHENTICATE_MIDDLEWARE_CONTAINER_PORT}:8000 \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -itd ${BACKEND_IMAGE_NAME}:${AUTHENTICATE_MIDDLEWARE_API_VERSION} \
    bash ./shell/backend_init.sh

docker exec -it ${BACKEND_CONTAINER_NAME} bash -c "
    cp ${CONTAINER_WORKDIR}/.env.sample ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_POSTGRES_DATABASE_NAME=/ s/$/${AUTHENTICATE_MIDDLEWARE_POSTGRES_DB}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_POSTGRES_PORT=/ s/$/${AUTHENTICATE_MIDDLEWARE_POSTGRES_CONTAINER_PORT}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_POSTGRES_USER=/ s/$/${AUTHENTICATE_MIDDLEWARE_POSTGRES_USER}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_POSTGRES_PASSWORD=/ s/$/${AUTHENTICATE_MIDDLEWARE_POSTGRES_PASSWORD}/' ${CONTAINER_WORKDIR}/.env
"

docker restart ${BACKEND_CONTAINER_NAME}

echo "##############################################################"
