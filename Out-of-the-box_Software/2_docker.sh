#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Insatll docker 20.10.21 :"
echo ""
apt install docker.io=20.10.21-0ubuntu1~20.04.2 -y
chmod 777 /var/run/docker.sock
usermod -aG docker $USER

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Configure docker settings :"
echo ""
rm /etc/docker/daemon.json

cat <<EOF > /etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2",
"insecure-registries": ["140.118.162.95", "${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}", "${CENTRAL_STORAGE_IP}"],
"registry-mirrors": ["http://140.118.162.95:80", "http://${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}"]
}
EOF

systemctl daemon-reload && systemctl restart docker

echo "##############################################################"
