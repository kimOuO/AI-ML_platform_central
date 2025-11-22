#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Build three zookeeper:3.9.3 :"
echo ""
docker rm -f zoo1
docker rm -f zoo2
docker rm -f zoo3
docker network rm zookeeper-network

docker network create zookeeper-network

# 分割zookeeper port
IFS=',' read -r TOPIC_MGT_ZOOKEEPER_PORT1 TOPIC_MGT_ZOOKEEPER_PORT2 TOPIC_MGT_ZOOKEEPER_PORT3 <<< "$TOPIC_MGT_ZOOKEEPER_PORT"

docker run -d \
--name zoo1 \
--hostname zoo1 \
--network zookeeper-network \
-p ${TOPIC_MGT_ZOOKEEPER_PORT1}:2181 \
-e ZOO_MY_ID=1 \
-e ZOO_SERVERS="server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181" \
--restart always \
zookeeper:3.9.3

docker run -d \
--name zoo2 \
--hostname zoo2 \
--network zookeeper-network \
-p ${TOPIC_MGT_ZOOKEEPER_PORT2}:2181 \
-e ZOO_MY_ID=2 \
-e ZOO_SERVERS="server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181" \
--restart always \
zookeeper:3.9.3

docker run -d \
--name zoo3 \
--hostname zoo3 \
--network zookeeper-network \
-p ${TOPIC_MGT_ZOOKEEPER_PORT3}:2181 \
-e ZOO_MY_ID=3 \
-e ZOO_SERVERS="server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181" \
--restart always \
zookeeper:3.9.3
