#!/bin/bash

# =====================================================
# environmental variables for common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Create .env file for ai_ml_mt-model_dev:"
echo ""

cat <<'EOF' > ./create_env.sh
#!/bin/bash

source .env.common

if [ ! -f ".env.sample" ]; then
echo "[ERROR] .env.sample doesn't exist."
exit 1
fi

if [ -f ".env" ]; then
echo "[INFO] .env already exists. Using the existing .env file."
else
echo "[INFO] Creating .env from .env.sample..."
cp .env.sample .env
fi

declare -A env_vars
env_vars["HOST_PASSWORD"]="mitlab"

env_vars["HTTP_HARBOR_HOST"]=${CENTRAL_STORAGE_IP}
env_vars["HTTP_HARBOR_PORT"]=${HARBOR_CONTAINER_PORT}
env_vars["HTTP_HARBOR_USER"]=${HARBOR_USER}
env_vars["HTTP_HARBOR_PASSWORD"]=${HARBOR_PASSWORD}

env_vars["HTTP_KUBEFLOW_HOST"]=${CENTRAL_HOST_IP}
env_vars["HTTP_KUBEFLOW_PORT"]=${KUBEFLOW_PORT}
env_vars["HTTP_KUBEFLOW_USER"]="user@example.com"
env_vars["HTTP_KUBEFLOW_PASSWORD"]="12341234"

env_vars["HTTP_TASK_MGT_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["HTTP_TASK_MGT_PORT"]=${MODEL_DEV_CONTAINER_PORT}
env_vars["HTTP_TASK_MGT_VERSION"]=${MODEL_DEV_API_VERSION}

env_vars["HTTP_ML_IMG_MGT_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["HTTP_ML_IMG_MGT_PORT"]=${IMG_MGT_CONTAINER_PORT}
env_vars["HTTP_ML_IMG_MGT_VERSION"]=${IMG_MGT_API_VERSION}

env_vars["HTTP_MODEL_DEV_PIPELINE_CONVERSION_NAME"]="pipeline_conversion"
env_vars["HTTP_MODEL_DEV_PIPELINE_CONVERSION_VERSION"]=${MODEL_DEV_API_VERSION}

env_vars["HTTP_PIPELINE_OPERATION_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["HTTP_PIPELINE_OPERATION_PORT"]=${AI_ML_MT_CONNECTOR_CONTAINER_PORT}
env_vars["HTTP_PIPELINE_OPERATION_VERSION"]=${AI_ML_MT_CONNECTOR_API_VERSION}

env_vars["AUTHENTICATE_MIDDLEWARE_CONTAINER_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["AUTHENTICATE_MIDDLEWARE_CONTAINER_PORT"]=${AUTHENTICATE_MIDDLEWARE_CONTAINER_PORT}
env_vars["AUTHENTICATE_MIDDLEWARE_CONTAINER_VERSION"]=${AUTHENTICATE_MIDDLEWARE_API_VERSION}

for var in "${!env_vars[@]}"; do
if grep -q "^$var=" .env; then
    sed -i "s|^$var=.*|$var=${env_vars[$var]}|" .env
else
    echo "$var=${env_vars[$var]}" >> .env
fi
done

EOF
echo "##############################################################"

echo ""
echo "##############################################################"
echo "Build ai_ml_mt-model_dev:"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/task-mgt_pipeline-conversion
export BACKEND_CONTAINER_NAME=ai_ml_mt-model_dev
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

ORIGINAL_USER=$(logname)
ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

docker rm -f ${BACKEND_CONTAINER_NAME}
# Run the Docker container
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${MODEL_DEV_CONTAINER_PORT}:8000 \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
    -v ${ORIGINAL_HOME}/.kube/config:${CONTAINER_WORKDIR}/main/apps/task_management/services/kubeconfig/config \
    -itd ${BACKEND_IMAGE_NAME}:v1.2.1\
    python manage.py runserver 0.0.0.0:8000

docker cp ./create_env.sh ${BACKEND_CONTAINER_NAME}:${CONTAINER_WORKDIR}
docker exec -it ${BACKEND_CONTAINER_NAME} bash create_env.sh
rm ./create_env.sh
echo "##############################################################"
docker restart ${BACKEND_CONTAINER_NAME}
