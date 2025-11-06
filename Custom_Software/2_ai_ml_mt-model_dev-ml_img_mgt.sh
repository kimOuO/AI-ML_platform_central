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

env_vars["HTTP_ML_IMG_MGT_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["HTTP_ML_IMG_MGT_PORT"]=${IMG_MGT_CONTAINER_PORT}
env_vars["HTTP_ML_IMG_MGT_VERSION"]=${IMG_MGT_API_VERSION}

env_vars["HTTP_PIPELINE_OPERATION_HOST_IP"]=${CENTRAL_HOST_IP}
env_vars["HTTP_PIPELINE_OPERATION_PORT"]=${AI_ML_MT_CONNECTOR_CONTAINER_PORT}
env_vars["HTTP_PIPELINE_OPERATION_VERSION"]=${AI_ML_MT_CONNECTOR_API_VERSION}

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
echo "Build ai_ml_mt-model_dev-ml_img_mgt:"
echo ""

export BACKEND_IMAGE_NAME=140.118.162.95/prod/ml-img-mgt
export BACKEND_CONTAINER_NAME=ai_ml_mt-model_dev-ml_img_mgt
export CONTAINER_WORKDIR=/app/${BACKEND_CONTAINER_NAME}

docker rm -f ${BACKEND_CONTAINER_NAME}
# Run the Docker container
docker run \
    --restart=always \
    --name ${BACKEND_CONTAINER_NAME} \
    -p ${IMG_MGT_CONTAINER_PORT}:8000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/usr/bin/docker \
    -v ${PWD}/../Environmental_Variables/.env.common:${CONTAINER_WORKDIR}/.env.common \
  -itd ${BACKEND_IMAGE_NAME}:${IMG_MGT_API_VERSION} \
  bash -lc "echo 'Waiting for .env before starting server...'; \ 
    until [ -f ${CONTAINER_WORKDIR}/.env ]; do sleep 1; done; \ 
    python manage.py runserver 0.0.0.0:8000"

docker cp ./create_env.sh ${BACKEND_CONTAINER_NAME}:${CONTAINER_WORKDIR}
docker exec -it -w ${CONTAINER_WORKDIR} ${BACKEND_CONTAINER_NAME} bash create_env.sh
rm ./create_env.sh
echo "##############################################################"