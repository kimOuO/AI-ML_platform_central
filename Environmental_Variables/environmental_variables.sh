#!/bin/bash

cd Environmental_Variables

# =====================================================
# env common
# =====================================================

export CENTRAL_HOST_IP=140.118.162.139
export CENTRAL_STORAGE_IP=172.16.200.148
########################################################################
cat <<EOF > .env.common
# =====================================================
# EXTERNAL_HOST_IP
# =====================================================
CENTRAL_HOST_IP=${CENTRAL_HOST_IP}
CENTRAL_STORAGE_IP=${CENTRAL_STORAGE_IP}

# Layer_sublayer - System - Abstract Class - Process
# =====================================================
# central_ai_ml_oom - metadata_mgt
# =====================================================
METADATA_MGT_CONTAINER_PORT=34902
METADATA_MGT_API_VERSION=v1.2.14

# =====================================================
# central_ai_ml_oom - file_mgt
# =====================================================
FILE_MGT_CONTAINER_PORT=34903
FILE_MGT_API_VERSION=v1.2.1

# =====================================================
# central_ai_ml_oom - ai_ml_mt_connector
# =====================================================
AI_ML_MT_CONNECTOR_CONTAINER_PORT=34904
AI_ML_MT_CONNECTOR_API_VERSION=v1.2.10

# =====================================================
# central_ai_ml_oom - bds_connector
# =====================================================
BDS_CONNECTOR_CONTAINER_PORT=34905
BDS_CONNECTOR_API_VERSION=v1.2.8

# =====================================================
# central_ai_ml_oom - agent_connector
# =====================================================
AGENT_CONNECTOR_CONTAINER_PORT=34906
AGENT_CONNECTOR_API_VERSION=v1.2.4

# =====================================================
# central_ai_ml_oom - aiml_authenticate_middleware
# =====================================================
AUTHENTICATE_MIDDLEWARE_CONTAINER_PORT=34901
AUTHENTICATE_MIDDLEWARE_API_VERSION=v1.2.4

# =====================================================
# central_ai_ml_oom - aiml_user_dashboard
# =====================================================
AIML_USER_DASHBOARD_CONTAINER_PORT=34915
AIML_USER_DASHBOARD_API_VERSION=v1.2.6

# =====================================================
# central_training - model_dev
# =====================================================
MODEL_DEV_CONTAINER_PORT=34917
NFS_SERVER_PATH=/nfs/kubeflow
KUBEFLOW_PORT=8080
MODEL_DEV_API_VERSION=v1.2.1

# =====================================================
# central_ai_ml_oom - harbor
# =====================================================
IMG_MGT_CONTAINER_PORT=34918
IMG_MGT_API_VERSION=v1.2.0
HARBOR_CONTAINER_PORT=30001
HARBOR_USER=mitlab
HARBOR_PASSWORD=Mitlab1234

# =====================================================
# central_bds - topic_mgt
# =====================================================
TOPIC_MGT_CONTAINER_PORT=34907
TOPIC_MGT_CONTAINER_API_VERSION=v1.2.0
TOPIC_MGT_KAFKA_PORT=34909,34910,34911
TOPIC_MGT_KAFKA_EXTERNAL_IP=${CENTRAL_HOST_IP}
TOPIC_MGT_ZOOKEEPER_PORT=34912,34913,34914
KAFDROP_PORT=34908
EOF

########################################################################

cat << 'EOF' > .env.postgres
# =====================================================
# environmental variables for central-metadata_resource_mgt
# =====================================================
METADATA_POSTGRES_CONTAINER_NAME=aiml_metadata_postgres
METADATA_POSTGRES_CONTAINER_PORT=30010
METADATA_POSTGRES_DB_BACKUP_PATH=/home/aiml_volume/metadata_db
METADATA_POSTGRES_DB=metadata_db
METADATA_POSTGRES_USER=root
METADATA_POSTGRES_PASSWORD=mitlab123456

# =====================================================
# environmental variables for central-permission_mgt 
# =====================================================
AUTHENTICATE_MIDDLEWARE_POSTGRES_CONTAINER_NAME=aiml_authenticate_postgres
AUTHENTICATE_MIDDLEWARE_POSTGRES_CONTAINER_PORT=30014
AUTHENTICATE_MIDDLEWARE_POSTGRES_DB_BACKUP_PATH=/home/aiml_volume/authenticate_db
AUTHENTICATE_MIDDLEWARE_POSTGRES_DB=authenticate_db
AUTHENTICATE_MIDDLEWARE_POSTGRES_USER=root
AUTHENTICATE_MIDDLEWARE_POSTGRES_PASSWORD=mitlab123456
EOF

cat << 'EOF' > .env.pgadmin
# =====================================================
# environmental variables for central-data_visualization  
# =====================================================
PGADMIN_CONTAINER_NAME=aiml_pgadmin
PGADMIN_CONTAINER_PORT=30013
PGADMIN_DEFAULT_EMAIL=root@gmail.com
PGADMIN_DEFAULT_PASSWORD=mitlab123456
EOF

cat << 'EOF' > .env.minio
# =====================================================
# environmental variables for central-file_resource_mgt 
# =====================================================
MINIO_CONTAINER_NAME=aiml_minio
MINIO_CONTAINER_PORT=30011
MINIO_CONSOLE_PORT=30012
MINIO_BACKUP_PATH=/home/ai_ml_minio/backup
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio123
EOF

cat << 'EOF' > .env.central-dashboard
# ==============================================
#                   DEFAULT
# ==============================================
PROTOCAL=http
HOST=${CENTRAL_HOST_IP}
PATH_NAME=/**
# ==============================================
# authenticate-authenticate_middleware-django
# ==============================================
API_ROOT=api
API_PORT=${AUTHENTICATE_MIDDLEWARE_CONTAINER_PORT}
API_VERSION=${AUTHENTICATE_MIDDLEWARE_API_VERSION}
# ==============================================
#                   Docker
# ==============================================
FRONTEND_INTERNAL_CONTAINER_PORT=3000
FRONTEND_IMAGE_NAME=ai_ml_user_dashboard
FRONTEND_CONTAINER_NAME=ai_ml_user_dashboard
FRONTEND_EXTERNAL_CONTAINER_PORT=${AIML_USER_DASHBOARD_CONTAINER_PORT}
# ==============================================
#                   Authorization
# ==============================================
AUTH_HEADER_TYPE=Bearer
ACCESS_TOKEN_NAME=auth_token
# ==============================================
#                   Etc
# ==============================================
EOF
