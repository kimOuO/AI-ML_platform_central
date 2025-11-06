#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

echo ""
echo "##############################################################"
echo "Download and save the GPG key :"
echo ""
mkdir -p /etc/apt/keyrings
chmod 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Configure the Kubernetes APT package repository :"
echo ""
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

cat /etc/apt/sources.list.d/kubernetes.list

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Update apt-get :"
echo ""
apt-get update

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Install kubelet kubeadm kubectl :"
echo ""
apt-get install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl

kubectl version --client 
kubelet --version
kubeadm version

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Close swap :"
echo ""
swapoff -a
sed -i '/\/swapfile/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )
sed -i '/\/swap.img/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Init kubernetes :"
echo ""
kubeadm init --pod-network-cidr=10.244.0.0/16

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Create K8s cluster configuration file path for root:"
echo ""

mkdir -p /$USER/.kube
sudo cp -i /etc/kubernetes/admin.conf /$USER/.kube/config
sudo chown $(id -u):$(id -g) /$USER/.kube/config

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Install flannel :"
echo ""
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Taint master node :"
echo ""
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Wait for node mitlab status to become Ready... :"
echo ""

while true; do
    # 獲取節點的狀態
    NODE_STATUS=$(kubectl get node ubuntu -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

    # 檢查節點是否處於 Ready 狀態
    if [[ "${NODE_STATUS}" == "True" ]]; then
        echo "Node mitlab status to be Ready "
        break
    else
        echo "Node mitlab status not to be Ready"
        # 等待 10 秒後重試
        sleep 10
    fi
done

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Create containerd config :"
echo ""

mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# 定義目標檔案
TARGET_FILE="/etc/containerd/config.toml"

# 使用 sed 在指定行後插入
MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\".tls]"

sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

MATCH_TEXT="configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
INSERT_TEXT='\ \ \ \ \ \ \ \ \ \ insecure_skip_verify = true'
sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_TEXT" "$TARGET_FILE"

########
MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"

# 使用 sed 在指定行後插入
sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.mirrors\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

MATCH_TEXT="mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
INSERT_CONTENT="\ \ \ \ \ \ \ \ \ \ endpoint = [\"http://$CENTRAL_STORAGE_IP:$HARBOR_CONTAINER_PORT\"]"
sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_CONTENT" "$TARGET_FILE"

# config.toml example
# # configs 
#       [plugins."io.containerd.grpc.v1.cri".registry.configs]
#         [plugins."io.containerd.grpc.v1.cri".registry.configs."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>".tls]
#           insecure_skip_verify = true
# # mirrors
#       [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
#         [plugins."io.containerd.grpc.v1.cri".registry.mirrors."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]
#           endpoint = ["http://<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Create K8s cluster configuration file path for user :"
echo ""
ORIGINAL_USER=$(logname)
ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

mkdir -p $ORIGINAL_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $ORIGINAL_HOME/.kube/config
sudo chown $(id -u "$ORIGINAL_USER"):$(id -g "$ORIGINAL_USER") $ORIGINAL_HOME/.kube/config

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Systemctl edit containerd :"
echo ""
# 定義目標 override 文件路徑
OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"

# 創建目標目錄（如果不存在）
mkdir -p "$(dirname "$OVERRIDE_FILE")"

# 向 override 文件中寫入配置
cat <<EOF > "$OVERRIDE_FILE"
[Service]
ExecStart=
ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
EOF

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Restart daemon containerd and docker :"
echo ""
systemctl daemon-reload
systemctl restart containerd
systemctl restart docker

echo "##############################################################"
