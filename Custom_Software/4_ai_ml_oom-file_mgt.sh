#!/bin/bash

# =====================================================
# environmental variables for central-file_resource_mgt
# =====================================================
source ../Environmental_Variables/.env.minio

# =====================================================
# environmental variables for common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build ai_ml_oom-file_mgt :"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/file-operation
export BACKEND_CONTAINER_NAME=aiml_file_mgt
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

docker rm -f ${BACKEND_CONTAINER_NAME}
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${FILE_MGT_CONTAINER_PORT}:8000 \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -itd ${BACKEND_IMAGE_NAME}:${FILE_MGT_API_VERSION} \
    bash ./shell/backend_init.sh

docker exec -it ${BACKEND_CONTAINER_NAME} bash -c "
    cp ${CONTAINER_WORKDIR}/.env.sample ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_MINIO_PORT=/ s/$/${MINIO_CONTAINER_PORT}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_MINIO_ROOT_USER=/ s/$/${MINIO_ROOT_USER}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_MINIO_ROOT_PASSWORD=/ s/$/${MINIO_ROOT_PASSWORD}/' ${CONTAINER_WORKDIR}/.env && \
    sed -i '/^HTTP_MINIO_SECURE=/ s/$/False/' ${CONTAINER_WORKDIR}/.env
"

docker restart ${BACKEND_CONTAINER_NAME}

echo "##############################################################"
