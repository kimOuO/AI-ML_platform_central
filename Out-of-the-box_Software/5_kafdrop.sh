#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build obsidinadynamics/kafdrop:4.0 :"
echo ""

docker rm -f kafdrop

# 分割KAFKA port
IFS=',' read -r TOPIC_MGT_KAFKA_PORT1 TOPIC_MGT_KAFKA_PORT2 TOPIC_MGT_KAFKA_PORT3 <<< "$TOPIC_MGT_KAFKA_PORT"
docker run -d --name kafdrop -p ${KAFDROP_PORT}:9000 \
    -e KAFKA_BROKERCONNECT=${TOPIC_MGT_KAFKA_EXTERNAL_IP}:${TOPIC_MGT_KAFKA_PORT1},${TOPIC_MGT_KAFKA_EXTERNAL_IP}:${TOPIC_MGT_KAFKA_PORT2},${TOPIC_MGT_KAFKA_EXTERNAL_IP}:${TOPIC_MGT_KAFKA_PORT3} \
    -e SERVER_SERVLET_CONTEXTPATH="/" \
    --restart always \
    obsidiandynamics/kafdrop:4.0.2

echo "##############################################################"
