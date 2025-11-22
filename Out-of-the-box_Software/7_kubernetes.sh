# # # #!/bin/bash

# # # # =====================================================
# # # # environmental variables for central-env.common
# # # # =====================================================
# # # source ../Environmental_Variables/.env.common

# # # echo ""
# # # echo "##############################################################"
# # # echo "Download and save the GPG key :"
# # # echo ""
# # # mkdir -p /etc/apt/keyrings
# # # chmod 755 /etc/apt/keyrings

# # # curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Configure the Kubernetes APT package repository :"
# # # echo ""
# # # echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# # # cat /etc/apt/sources.list.d/kubernetes.list

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Update apt-get :"
# # # echo ""
# # # apt-get update

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Install kubelet kubeadm kubectl :"
# # # echo ""
# # # apt-get install kubelet kubeadm kubectl -y
# # # apt-mark hold kubelet kubeadm kubectl

# # # kubectl version --client 
# # # kubelet --version
# # # kubeadm version

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Close swap :"
# # # echo ""
# # # swapoff -a
# # # sed -i '/\/swapfile/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )
# # # sed -i '/\/swap.img/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Init kubernetes :"
# # # echo ""
# # # kubeadm init --pod-network-cidr=10.244.0.0/16

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Create K8s cluster configuration file path for root:"
# # # echo ""

# # # mkdir -p /$USER/.kube
# # # sudo cp -i /etc/kubernetes/admin.conf /$USER/.kube/config
# # # sudo chown $(id -u):$(id -g) /$USER/.kube/config

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Install flannel :"
# # # echo ""
# # # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Taint master node :"
# # # echo ""
# # # kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Wait for node mitlab status to become Ready... :"
# # # echo ""

# # # while true; do
# # #     # 獲取節點的狀態
# # #     NODE_STATUS=$(kubectl get node ubuntu -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

# # #     # 檢查節點是否處於 Ready 狀態
# # #     if [[ "${NODE_STATUS}" == "True" ]]; then
# # #         echo "Node mitlab status to be Ready "
# # #         break
# # #     else
# # #         echo "Node mitlab status not to be Ready"
# # #         # 等待 10 秒後重試
# # #         sleep 10
# # #     fi
# # # done

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Create containerd config :"
# # # echo ""

# # # mkdir -p /etc/containerd
# # # containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# # # # 定義目標檔案
# # # TARGET_FILE="/etc/containerd/config.toml"

# # # # 使用 sed 在指定行後插入
# # # MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\".tls]"

# # # sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

# # # MATCH_TEXT="configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# # # INSERT_TEXT='\ \ \ \ \ \ \ \ \ \ insecure_skip_verify = true'
# # # sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_TEXT" "$TARGET_FILE"

# # # ########
# # # MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"

# # # # 使用 sed 在指定行後插入
# # # sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.mirrors\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

# # # MATCH_TEXT="mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# # # INSERT_CONTENT="\ \ \ \ \ \ \ \ \ \ endpoint = [\"http://$CENTRAL_STORAGE_IP:$HARBOR_CONTAINER_PORT\"]"
# # # sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_CONTENT" "$TARGET_FILE"

# # # # config.toml example
# # # # # configs 
# # # #       [plugins."io.containerd.grpc.v1.cri".registry.configs]
# # # #         [plugins."io.containerd.grpc.v1.cri".registry.configs."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>".tls]
# # # #           insecure_skip_verify = true
# # # # # mirrors
# # # #       [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
# # # #         [plugins."io.containerd.grpc.v1.cri".registry.mirrors."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]
# # # #           endpoint = ["http://<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Create K8s cluster configuration file path for user :"
# # # echo ""
# # # ORIGINAL_USER=$(logname)
# # # ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

# # # mkdir -p $ORIGINAL_HOME/.kube
# # # sudo cp -i /etc/kubernetes/admin.conf $ORIGINAL_HOME/.kube/config
# # # sudo chown $(id -u "$ORIGINAL_USER"):$(id -g "$ORIGINAL_USER") $ORIGINAL_HOME/.kube/config

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Systemctl edit containerd :"
# # # echo ""
# # # # 定義目標 override 文件路徑
# # # OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"

# # # # 創建目標目錄（如果不存在）
# # # mkdir -p "$(dirname "$OVERRIDE_FILE")"

# # # # 向 override 文件中寫入配置
# # # cat <<EOF > "$OVERRIDE_FILE"
# # # [Service]
# # # ExecStart=
# # # ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
# # # EOF

# # # echo "##############################################################"

# # # echo ""
# # # echo "##############################################################"
# # # echo "Restart daemon containerd and docker :"
# # # echo ""
# # # systemctl daemon-reload
# # # systemctl restart containerd
# # # systemctl restart docker

# # # echo "##############################################################"
# # #!/usr/bin/env bash

# # # =====================================================
# # # Load environmental variables for central-env.common
# # # =====================================================
# # source ../Environmental_Variables/.env.common

# # set -euo pipefail

# # # 取得原本登入的使用者（非 root）
# # ORIGINAL_USER=${SUDO_USER:-$(logname)}
# # ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

# # echo ">>> Target kubectl user: ${ORIGINAL_USER} (${ORIGINAL_HOME})"

# # # ------------------------------------------------------------
# # # 1. Close swap
# # # ------------------------------------------------------------
# # echo ">>> [1] Disable swap"

# # swapoff -a
# # # 把常見的 swap 設定註解掉
# # sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true
# # sed -i '/\/swapfile/s/^/# /' /etc/fstab || true
# # sed -i '/\/swap.img/s/^/# /' /etc/fstab || true

# # # ------------------------------------------------------------
# # # 2. Sysctl and kernel modules
# # # ------------------------------------------------------------
# # echo ">>> [2] Configure sysctl and kernel modules"

# # # 確保模組載入
# # modprobe overlay || true
# # modprobe br_netfilter || true

# # # 開機自動載入模組
# # cat <<EOF >/etc/modules-load.d/k8s.conf
# # br_netfilter
# # overlay
# # EOF

# # # 設定網路相關 sysctl
# # cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
# # net.bridge.bridge-nf-call-iptables  = 1
# # net.bridge.bridge-nf-call-ip6tables = 1
# # net.ipv4.ip_forward                 = 1
# # EOF

# # sysctl --system

# # # # ------------------------------------------------------------
# # # # 3. Install containerd (if not exist)
# # # # ------------------------------------------------------------
# # # echo ">>> [3] Install containerd if needed"

# # # apt-get update -y
# # # apt-get install -y containerd

# # # 建立預設 config
# # echo ">>> Generate default containerd config"
# # /bin/mkdir -p /etc/containerd
# # containerd config default >/etc/containerd/config.toml

# # TARGET_FILE="/etc/containerd/config.toml"

# # # 啟用 systemd cgroup，與 kubelet 預設一致
# # sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$TARGET_FILE"

# # # ------------------------------------------------------------
# # # 4. Configure containerd registry for Harbor (HTTP + insecure)
# # # ------------------------------------------------------------
# # echo ">>> [4] Configure containerd registry for Harbor (${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT})"

# # # 插入 configs (tls.insecure_skip_verify = true)
# # MIRROR_ENTRY="        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\".tls]"
# # sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

# # MATCH_TEXT="configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# # INSERT_TEXT='          insecure_skip_verify = true'
# # sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_TEXT" "$TARGET_FILE"

# # # 插入 mirrors (endpoint = ["http://IP:PORT"])
# # MIRROR_ENTRY2="        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"
# # sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.mirrors\]/a '"$MIRROR_ENTRY2" "$TARGET_FILE"

# # MATCH_TEXT2="mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# # INSERT_CONTENT="          endpoint = [\"http://${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"
# # sed -i '/'"$MATCH_TEXT2"'/a '"$INSERT_CONTENT" "$TARGET_FILE"

# # # ------------------------------------------------------------
# # # 5. systemd override for containerd
# # # ------------------------------------------------------------
# # echo ">>> [5] Configure systemd override for containerd"

# # OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"
# # mkdir -p "$(dirname "$OVERRIDE_FILE")"

# # cat <<EOF >"$OVERRIDE_FILE"
# # [Service]
# # ExecStart=
# # ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
# # EOF

# # systemctl daemon-reload
# # systemctl restart containerd

# # # ------------------------------------------------------------
# # # 6. Install Kubernetes repo & packages
# # # ------------------------------------------------------------
# # echo ">>> [6] Install Kubernetes 1.32 repository and packages"

# # mkdir -p /etc/apt/keyrings
# # chmod 755 /etc/apt/keyrings

# # curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
# #   | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# # cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
# # deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
# # EOF

# # apt-get update -y
# # apt-get install -y kubelet kubeadm kubectl
# # apt-mark hold kubelet kubeadm kubectl

# # # ------------------------------------------------------------
# # # 7. kubeadm init
# # # ------------------------------------------------------------
# # echo ">>> [7] Run kubeadm init"

# # kubeadm init --pod-network-cidr=10.244.0.0/16 --v=5

# # # 之後整個 script 用 admin.conf 當 kubeconfig
# # export KUBECONFIG=/etc/kubernetes/admin.conf

# # # 讓 control-plane 也能排工作負載
# # echo ">>> Remove control-plane taint (allow scheduling on master)"
# # kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# # # ------------------------------------------------------------
# # # 8. Install flannel CNI and wait
# # # ------------------------------------------------------------
# # echo ">>> [8] Install flannel CNI"

# # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# # echo ">>> Wait for flannel pods to be Ready..."
# # while true; do
# #   READY=$(kubectl get pod -n kube-flannel -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | grep -c true || true)
# #   if [[ "$READY" -ge 1 ]]; then
# #     echo ">>> flannel is Ready."
# #     break
# #   else
# #     echo ">>> flannel is still starting, retry in 10 seconds..."
# #     sleep 10
# #   fi
# # done

# # # ------------------------------------------------------------
# # # 9. Wait for node Ready
# # # ------------------------------------------------------------
# # echo ">>> [9] Wait for node to become Ready..."

# # while true; do
# #   NODE_STATUS=$(kubectl get node -o=jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' || echo "False")
# #   if [[ "${NODE_STATUS}" == "True" ]]; then
# #     NODE_NAME=$(kubectl get node -o=jsonpath='{.items[0].metadata.name}')
# #     echo ">>> Node ${NODE_NAME} is Ready!"
# #     break
# #   else
# #     echo ">>> Node is not Ready yet, retry in 10 seconds..."
# #     sleep 10
# #   fi
# # done

# # # ------------------------------------------------------------
# # # 10. Copy kubeconfig to original login user
# # # ------------------------------------------------------------
# # echo ">>> [10] Copy kubeconfig to original user: ${ORIGINAL_USER}"

# # mkdir -p "${ORIGINAL_HOME}/.kube"
# # cp -i /etc/kubernetes/admin.conf "${ORIGINAL_HOME}/.kube/config"
# # chown "$(id -u "$ORIGINAL_USER")":"$(id -g "$ORIGINAL_USER")" "${ORIGINAL_HOME}/.kube/config"

# # echo ">>> Copy kubeconfig to root user as well"

# # mkdir -p /root/.kube
# # cp -i /etc/kubernetes/admin.conf /root/.kube/config
# # chown root:root /root/.kube/config


# # echo "============================================================"
# # echo "Kubernetes + containerd + flannel setup is DONE."
# # echo "You can now run (as ${ORIGINAL_USER}):"
# # echo "  kubectl get nodes"
# # echo "  kubectl get pods -A"
# # echo "============================================================"
# #!/bin/bash
# set -euo pipefail

# # ============================================================
# # 0. 載入環境變數（主要是 NFS 的 IP / 路徑 + Harbor 設定）
# # ============================================================
# source ../Environmental_Variables/.env.common

# # ============================================================
# # 0.1 設定兩個 Harbor Registry
# # ============================================================
# # 1) Kubeflow 用的 Harbor Proxy Cache（改寫 ghcr.io → 這個 registry）
# HARBOR_PROXY_HOST="140.118.162.139:35301"

# # 2) 訓練用 image 所在的 Harbor（例如 140.118.162.95:32000 這種）
# TRAIN_REGISTRY_HOST="${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}"

# # 取得原本登入的使用者（非 root）
# ORIGINAL_USER=${SUDO_USER:-$(logname)}
# ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

# echo ">>> Target kubectl user: ${ORIGINAL_USER} (${ORIGINAL_HOME})"

# # ------------------------------------------------------------
# # 1. Disable swap
# # ------------------------------------------------------------
# echo ">>> [1] Disable swap"

# swapoff -a || true
# # 把常見的 swap 設定註解掉
# sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true
# sed -i '/\/swapfile/s/^/# /' /etc/fstab || true
# sed -i '/\/swap.img/s/^/# /' /etc/fstab || true

# # ------------------------------------------------------------
# # 2. Sysctl and kernel modules
# # ------------------------------------------------------------
# echo ">>> [2] Configure sysctl and kernel modules"

# # 確保模組載入
# modprobe overlay || true
# modprobe br_netfilter || true

# # 開機自動載入模組
# cat <<EOF >/etc/modules-load.d/k8s.conf
# br_netfilter
# overlay
# EOF

# # 設定網路相關 sysctl
# cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
# net.bridge.bridge-nf-call-iptables  = 1
# net.bridge.bridge-nf-call-ip6tables = 1
# net.ipv4.ip_forward                 = 1
# EOF

# sysctl --system

# # ------------------------------------------------------------
# # 3. 產生 containerd 預設設定檔 + 啟用 systemd cgroup
# # ------------------------------------------------------------
# echo ">>> [3] Generate default containerd config"

# mkdir -p /etc/containerd
# containerd config default >/etc/containerd/config.toml

# TARGET_FILE="/etc/containerd/config.toml"

# # 啟用 systemd cgroup，與 kubelet 預設一致
# sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$TARGET_FILE" || true

# # ------------------------------------------------------------
# # 4. 調整 containerd registry：啟用 config_path，並為兩個 Harbor 建 hosts.toml
# # ------------------------------------------------------------
# echo ">>> [4] Configure containerd registry for Harbor Proxy (${HARBOR_PROXY_HOST}) and Train Harbor (${TRAIN_REGISTRY_HOST})"

# # 4-1) 啟用 registry.config_path = "/etc/containerd/certs.d"
# # 預設 config 會有一行：config_path = ""
# if grep -q 'config_path = ""' "$TARGET_FILE"; then
#   sed -i 's#config_path = ""#config_path = "/etc/containerd/certs.d"#' "$TARGET_FILE"
# else
#   # 若沒有，則在 registry 區塊塞一行（一般不會走到這裡，但保險一下）
#   sed -i 's/\[plugins\."io.containerd.grpc.v1.cri"\.registry\]/[plugins."io.containerd.grpc.v1.cri".registry]\n  config_path = "\/etc\/containerd\/certs.d"/' "$TARGET_FILE"
# fi

# # （重要）不再使用 registry.mirrors 來轉 ghcr.io，避免 /v2 路徑對不起來
# # 我們改用 hosts.toml 來直接宣告每一個 registry。

# # 4-2) 為 Kubeflow Harbor Proxy 建立 hosts.toml，宣告它是一個 HTTP registry，可以 pull / resolve
# mkdir -p "/etc/containerd/certs.d/${HARBOR_PROXY_HOST}"

# cat >"/etc/containerd/certs.d/${HARBOR_PROXY_HOST}/hosts.toml" <<EOF
# server = "http://${HARBOR_PROXY_HOST}"

# [host."http://${HARBOR_PROXY_HOST}"]
#   capabilities = ["pull", "resolve"]
#   skip_verify = true
# EOF

# # 4-3) 為「訓練用 Harbor」建立 hosts.toml，讓節點可以從這裡拉訓練 image
# mkdir -p "/etc/containerd/certs.d/${TRAIN_REGISTRY_HOST}"

# cat >"/etc/containerd/certs.d/${TRAIN_REGISTRY_HOST}/hosts.toml" <<EOF
# server = "http://${TRAIN_REGISTRY_HOST}"

# [host."http://${TRAIN_REGISTRY_HOST}"]
#   # 如果之後要從節點 push image 上去，可以加上 "push"
#   capabilities = ["pull", "resolve"]
#   skip_verify = true
# EOF

# echo ">>> containerd registry config_path = /etc/containerd/certs.d"
# echo ">>> hosts.toml created for:"
# echo "    - ${HARBOR_PROXY_HOST} (Kubeflow Proxy Cache)"
# echo "    - ${TRAIN_REGISTRY_HOST} (Training Images Harbor)"

# # ------------------------------------------------------------
# # 5. systemd override for containerd
# # ------------------------------------------------------------
# echo ">>> [5] Configure systemd override for containerd"

# OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"
# mkdir -p "$(dirname "$OVERRIDE_FILE")"

# cat <<EOF >"$OVERRIDE_FILE"
# [Service]
# ExecStart=
# ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
# EOF

# systemctl daemon-reload
# systemctl restart containerd

# echo ">>> containerd restarted. You can verify with: crictl info | sed -n '/\"registry\"/,/\"sandboxImage\"/p'"

# # ------------------------------------------------------------
# # 6. Install Kubernetes repo & packages
# # ------------------------------------------------------------
# echo ">>> [6] Install Kubernetes 1.32 repository and packages"

# mkdir -p /etc/apt/keyrings
# chmod 755 /etc/apt/keyrings

# curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
#   | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
# EOF

# apt-get update -y
# apt-get install -y kubelet kubeadm kubectl
# apt-mark hold kubelet kubeadm kubectl

# # ------------------------------------------------------------
# # 7. kubeadm init
# # ------------------------------------------------------------
# echo ">>> [7] Run kubeadm init"

# kubeadm init --pod-network-cidr=10.244.0.0/16 --v=5

# # 之後整個 script 用 admin.conf 當 kubeconfig
# export KUBECONFIG=/etc/kubernetes/admin.conf

# # 讓 control-plane 也能排工作負載
# echo ">>> Remove control-plane taint (allow scheduling on master)"
# kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# # ------------------------------------------------------------
# # 8. Install flannel CNI and wait
# # ------------------------------------------------------------
# echo ">>> [8] Install flannel CNI"

# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# echo ">>> Wait for flannel pods to be Ready..."
# while true; do
#   READY=$(kubectl get pod -n kube-flannel -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | grep -c true || true)
#   if [[ "$READY" -ge 1 ]]; then
#     echo ">>> flannel is Ready."
#     break
#   else
#     echo ">>> flannel is still starting, retry in 10 seconds..."
#     sleep 10
#   fi
# done

# # ------------------------------------------------------------
# # 9. Wait for node Ready
# # ------------------------------------------------------------
# echo ">>> [9] Wait for node to become Ready..."

# while true; do
#   NODE_STATUS=$(kubectl get node -o=jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' || echo "False")
#   if [[ "${NODE_STATUS}" == "True" ]]; then
#     NODE_NAME=$(kubectl get node -o=jsonpath='{.items[0].metadata.name}')
#     echo ">>> Node ${NODE_NAME} is Ready!"
#     break
#   else
#     echo ">>> Node is not Ready yet, retry in 10 seconds..."
#     sleep 10
#   fi
# done

# # ------------------------------------------------------------
# # 10. Copy kubeconfig to original login user + root
# # ------------------------------------------------------------
# echo ">>> [10] Copy kubeconfig to original user: ${ORIGINAL_USER}"

# mkdir -p "${ORIGINAL_HOME}/.kube"

# # 如果 ~/.kube/config 被誤建成目錄，先刪掉
# if [ -d "${ORIGINAL_HOME}/.kube/config" ]; then
#   rm -rf "${ORIGINAL_HOME}/.kube/config"
# fi

# cp -i /etc/kubernetes/admin.conf "${ORIGINAL_HOME}/.kube/config"
# chown "$(id -u "$ORIGINAL_USER")":"$(id -g "$ORIGINAL_USER")" "${ORIGINAL_HOME}/.kube/config"

# echo ">>> Copy kubeconfig to root user as well"

# mkdir -p /root/.kube

# if [ -d /root/.kube/config ]; then
#   rm -rf /root/.kube/config
# fi

# cp -i /etc/kubernetes/admin.conf /root/.kube/config
# chown root:root /root/.kube/config

# echo "============================================================"
# echo "Kubernetes + containerd + flannel + TWO Harbor registries setup is DONE."
# echo "Harbor Proxy (Kubeflow images):          ${HARBOR_PROXY_HOST}"
# echo "Train Harbor (training images registry): ${TRAIN_REGISTRY_HOST}"
# echo "You can now run (as ${ORIGINAL_USER}):"
# echo "  kubectl get nodes"
# echo "  kubectl get pods -A"
# echo "============================================================"
#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# ============================================================
# 0. 載入環境變數
#    需要 CENTRAL_STORAGE_IP / NFS_SERVER_PATH / HARBOR_PROXY_REGISTRY 等
# ============================================================
source ../Environmental_Variables/.env.common

# Kubeflow namespace（預設 kubeflow）
KFP_NAMESPACE="kubeflow"

# ============================================================
# 0.1 Harbor Proxy 設定：把 ghcr.io 改成 Harbor Proxy
# ============================================================
# 之後所有 kustomize build 出來的 YAML，只要有 ghcr.io/ 開頭的 image，
# 都會被 rewrite 成：${HARBOR_PROXY_REGISTRY}/...
HARBOR_PROXY_REGISTRY="${HARBOR_PROXY_REGISTRY:-140.118.162.139:35301/ghcr}"

rewrite_ghcr_to_harbor() {
  # 把 YAML 裡所有 ghcr.io/... 改成 ${HARBOR_PROXY_REGISTRY}/...
  sed "s#ghcr.io/#${HARBOR_PROXY_REGISTRY}/#g"
}

kf_apply() {
  local path="$1"
  echo "[KF+Harbor] kustomize build ${path} | rewrite_ghcr_to_harbor | kubectl apply -f -"
  kustomize build "${path}" \
    | rewrite_ghcr_to_harbor \
    | kubectl apply -f -
}

echo "##############################################################"
echo "Set NFS server for kubeflow:"
echo "##############################################################"
echo ""

# # ------------------------------------------------------------
# # 1. 安裝 NFS Subdir External Provisioner
# # ------------------------------------------------------------
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# # 這裡改成「寫死」的 IP + 路徑
# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
#   --create-namespace \
#   --namespace nfs-provisioner \
#   --set nfs.server=${CENTRAL_STORAGE_IP} \
#   --set nfs.path=${NFS_SERVER_PATH}

# # ================== 設定 nfs-client 為預設 StorageClass，避免 PVC Pending ==================
# echo "============================================================"
# echo "[NFS] 設定 nfs-client 為預設 StorageClass，避免 PVC 沒指定時卡 Pending"
# echo "============================================================"

# # 等待 nfs-client StorageClass 建立（最多等 30 次，每次 5 秒）
# for i in {1..30}; do
#   if kubectl get sc nfs-client >/dev/null 2>&1; then
#     echo "[INFO] 找到 StorageClass nfs-client"
#     break
#   fi
#   echo "[INFO] 等待 nfs-client StorageClass 建立中 (${i}/30)..."
#   sleep 5
# done

# # 將 nfs-client 設為 default StorageClass（若失敗只印 WARNING，不中斷整個腳本）
# if kubectl get sc nfs-client >/dev/null 2>&1; then
#   kubectl patch storageclass nfs-client \
#     -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' \
#     && echo "[INFO] 已將 nfs-client 設為預設 StorageClass" \
#     || echo "[WARN] 設定 nfs-client 為預設 StorageClass 失敗，請手動檢查"
# else
#   echo "[WARN] 仍然找不到 StorageClass nfs-client，PVC 可能會卡 Pending，請手動檢查"
# fi
# # ================== NFS 區塊結束 ================================================================

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Build kubeflow :"
# echo "##############################################################"
# echo ""
# # ------------------------------------------------------------
# # 2. 下載 Kubeflow manifests 與 kustomize
# # ------------------------------------------------------------
# git clone https://github.com/kubeflow/manifests.git
cd manifests
# git checkout v1.10-branch
# wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz

# # Unzip kustomize and Configure kustomize
# tar -xzvf kustomize_v5.4.3_linux_amd64.tar.gz
# chmod 777 kustomize
# mv kustomize /usr/bin/kustomize

# # ------------------------------------------------------------
# # 2.5 先建立 kubeflow namespace（避免後面一堆 namespaces "kubeflow" not found）
# # ------------------------------------------------------------
# echo "============================================================"
# echo "[2.5] 建立 kubeflow namespace"
# echo "============================================================"

# kubectl create namespace "${KFP_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# # ------------------------------------------------------------
# # 3. 安裝 cert-manager
# # ------------------------------------------------------------
# echo "============================================================"
# echo "[3] 安裝 cert-manager"
# echo "============================================================"

# 1) 先安裝 cert-manager 本體
kf_apply common/cert-manager/base

# 2) 等 deployment Ready（含 webhook）
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-webhook
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-cainjector

# 3) 再安裝 Kubeflow issuer（這時 webhook 已經 ready）
kf_apply common/cert-manager/kubeflow-issuer/base

# ------------------------------------------------------------
# 4. 安裝 Istio (Kubeflow 預設設定)
# ------------------------------------------------------------
echo "============================================================"
echo "[4] 安裝 Istio (Kubeflow 預設設定)"
echo "============================================================"

# Istio CRDs
kf_apply common/istio/istio-crds/base
# Istio namespace + 基本設定
kf_apply common/istio/istio-namespace/base
# Istio 安裝（使用 oauth2-proxy overlay）
kf_apply common/istio/istio-install/overlays/oauth2-proxy

kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istiod
kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istio-ingressgateway

# ------------------------------------------------------------
# 5. OAuth2-proxy + Dex（登入機制）
# ------------------------------------------------------------
echo "============================================================"
echo "[5] OAuth2-proxy + Dex（登入機制）"
echo "============================================================"

# OAuth2-proxy
kf_apply common/oauth2-proxy/overlays/m2m-dex-only/
kubectl wait --for=condition=Available --timeout=300s -n oauth2-proxy deployment/oauth2-proxy

# Dex（預設帳密：user@example.com / 12341234）
kf_apply common/dex/overlays/oauth2-proxy
kubectl wait --for=condition=Available --timeout=300s -n auth deployment/dex

# ------------------------------------------------------------
# 6. NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines Core
# ------------------------------------------------------------
echo "============================================================"
echo "[6] NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines"
echo "============================================================"

# NetworkPolicy
kf_apply common/networkpolicies/base

# Kubeflow Roles (ClusterRoles / ClusterRoleBindings 等)
kf_apply common/kubeflow-roles/base

# Kubeflow Istio 資源（VirtualService / Gateway 等）
kf_apply common/istio/kubeflow-istio-resources/base

# Kubeflow Pipelines (multi-user, cert-manager 版本)
# 部分環境會跳 DecoratorController / namespace 等警告，但不影響後續，可忽略
set +o errexit
kf_apply applications/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user || \
  echo "[WARN] Some Pipeline resources may have failed on first apply (e.g. DecoratorController). You can re-run this kustomize later if needed."
set -o errexit

# 先等 ml-pipeline-ui 起來（如果還沒建成功會 timeout，但腳本會照規則等）
kubectl wait --for=condition=Available --timeout=600s -n "${KFP_NAMESPACE}" deployment/ml-pipeline-ui || \
  echo "[WARN] ml-pipeline-ui not Ready yet. Please check later with: kubectl get pods -n ${KFP_NAMESPACE}"

# ------------------------------------------------------------
# 6.1 關閉 Kubeflow Pipelines 的 cache webhook（cache-webhook-kubeflow）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.1] 關閉 Kubeflow Pipelines 的 cache webhook（cache-webhook-kubeflow）"
echo "============================================================"

CACHE_WEBHOOK_NAME="cache-webhook-kubeflow"
if kubectl get mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" &>/dev/null; then
  echo "[INFO] Found mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME}, patching to only allow DELETE..."
  kubectl patch mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" \
    --type='json' \
    -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'
  echo "[INFO] cache-webhook-kubeflow patched successfully."
else
  echo "[WARN] mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME} not found, skip cache webhook patch."
fi

# ------------------------------------------------------------
# 6.2 關閉 Kubeflow Pipelines 相關 DestinationRule 的 mTLS（TLS → DISABLE）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.2] Patch Kubeflow Pipelines DestinationRule TLS = DISABLE"
echo "============================================================"

DEST_RULES=(
  ml-pipeline
  ml-pipeline-ui
  ml-pipeline-visualizationserver
  metadata-grpc-service
  ml-pipeline-minio
  ml-pipeline-mysql
)

for dr in "${DEST_RULES[@]}"; do
  if kubectl -n "${KFP_NAMESPACE}" get destinationrule "${dr}" &>/dev/null; then
    echo "  - Patching DestinationRule: ${dr}"
    kubectl -n "${KFP_NAMESPACE}" patch destinationrule "${dr}" \
      --type='json' \
      -p='[{"op":"replace","path":"/spec/trafficPolicy/tls","value":{"mode":"DISABLE"}}]'
  else
    echo "  - DestinationRule ${dr} not found, skip."
  fi
done

# ------------------------------------------------------------
# 6.3 修復 Kubeflow Pipelines 使用的 MySQL（root 帳號 / plugin / DB）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.3] 修復 Kubeflow MySQL 設定（root plugin + metadb/mlpipeline/cachedb）"
echo "============================================================"

echo "[MySQL Fix] 尋找 MySQL Pod (label app=mysql, namespace=${KFP_NAMESPACE})"

MYSQL_POD=""
for i in {1..30}; do
  MYSQL_POD=$(kubectl -n "${KFP_NAMESPACE}" get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "${MYSQL_POD}" ]]; then
    PHASE=$(kubectl -n "${KFP_NAMESPACE}" get pod "${MYSQL_POD}" -o jsonpath='{.status.phase}' || echo "Unknown")
    echo "[INFO] 找到 MySQL Pod: ${MYSQL_POD}, phase=${PHASE}"
    if [[ "${PHASE}" == "Running" ]]; then
      break
    fi
  else
    echo "[INFO] 尚未找到 MySQL Pod，等待中 (${i}/30)..."
  fi
  sleep 5
done

if [[ -z "${MYSQL_POD}" ]]; then
  echo "[ERROR] 無法在 namespace=${KFP_NAMESPACE} 找到 app=mysql 的 Pod，請確認 Kubeflow Pipelines 是否已安裝。"
  exit 1
fi

# 🔥 新增：等待 mysqld 真的 Ready（避免 socket 連不到）
echo "[MySQL Fix] 等待 mysqld ready（mysqladmin ping）..."

MYSQL_READY=0
for i in {1..60}; do
  if kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
       sh -c "mysqladmin ping -u root --silent" >/dev/null 2>&1; then
    echo "[INFO] MySQL 已經就緒（mysqld 回應 ping）。"
    MYSQL_READY=1
    break
  fi
  echo "[INFO] MySQL 尚未 ready，重試中 (${i}/60)..."
  sleep 5
done

if [[ "${MYSQL_READY}" -ne 1 ]]; then
  echo "[ERROR] 等待 mysqld 超時，仍然無法 ping 通，請先手動檢查 MySQL Pod log。"
  exit 1
fi

echo "[MySQL Fix] 在 MySQL 中修正 root 帳號 / plugin / 建立 DB"

kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- mysql -u root << 'EOSQL'
-- =========================================================
-- 調整 root 帳號：
--   - root@localhost / root@'%' 使用 mysql_native_password + 空密碼
--   - root@'%' 允許從其他 Pod 連線
-- =========================================================

ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';

CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '';

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

-- =========================================================
-- 建立 Kubeflow 需要的三個 DB（若不存在）
--   - metadb      : 給 metadata-grpc (MLMD)
--   - mlpipeline  : 給 ml-pipeline / persistenceagent / scheduledworkflow
--   - cachedb     : 給 cache-server
-- =========================================================
CREATE DATABASE IF NOT EXISTS metadb;
CREATE DATABASE IF NOT EXISTS mlpipeline;
CREATE DATABASE IF NOT EXISTS cachedb;
EOSQL

echo "[MySQL Fix] MySQL 初始化 SQL 執行完成，檢查當前狀態："

echo "[INFO] 使用者 plugin 狀態 (應該看到 root@'%' 與 root@'localhost' 為 mysql_native_password)："
kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
  mysql -u root -e "SELECT user, host, plugin FROM mysql.user;"

echo ""
echo "[INFO] 資料庫列表 (應該至少有 metadb / mlpipeline / cachedb)："
kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
  mysql -u root -e "SHOW DATABASES;"

# ------------------------------------------------------------
# 6.4 重啟 Pipelines 相關 Pod（套用 DestinationRule + MySQL 修復）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.4] 重啟 Kubeflow Pipelines Pods（套用 TLS 設定與 MySQL 修復結果）"
echo "============================================================"

echo "[INFO] Restart Kubeflow Pipelines Pods to pick up new DestinationRule and MySQL settings..."
kubectl -n "${KFP_NAMESPACE}" delete pod -l application-crd-id=kubeflow-pipelines --ignore-not-found

# ------------------------------------------------------------
# 7. 安裝 Central Dashboard
# ------------------------------------------------------------
echo "============================================================"
echo "[7] 安裝 Central Dashboard"
echo "============================================================"

kf_apply applications/centraldashboard/overlays/oauth2-proxy

kubectl wait --for=condition=Available --timeout=600s -n "${KFP_NAMESPACE}" deployment/centraldashboard || \
  echo "[WARN] centraldashboard not Ready yet. Please check: kubectl get pods -n ${KFP_NAMESPACE}"

# ------------------------------------------------------------
# 8. Profiles + 預設使用者 (kubeflow-user-example-com)
# ------------------------------------------------------------
echo "============================================================"
echo "[8] Profiles + 預設使用者 (kubeflow-user-example-com)"
echo "============================================================"

# Profiles + KFAM（安裝 CRD / controller）
kf_apply applications/profiles/upstream/overlays/kubeflow

# 建立一個預設 Profile（user@example.com）
cat << 'EOF' | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: kubeflow-user-example-com
spec:
  owner:
    kind: User
    name: user@example.com
EOF

# ================== [8.1 修正版] 同步 mlpipeline-minio-artifact Secret 到 user namespace ==================
echo "============================================================"
echo "[8.1] 同步 mlpipeline-minio-artifact Secret 到 kubeflow-user-example-com"
echo "============================================================"

# 先等 Profile 幫忙建立 namespace kubeflow-user-example-com（最多等 30 次，每次 5 秒）
for i in {1..30}; do
  if kubectl get namespace kubeflow-user-example-com >/dev/null 2>&1; then
    echo "[INFO] Profile namespace kubeflow-user-example-com 已建立"
    break
  fi
  echo "[INFO] 等待 namespace kubeflow-user-example-com 建立中 (${i}/30)..."
  sleep 5
done

if kubectl get namespace kubeflow-user-example-com >/dev/null 2>&1; then
  # 確認在 kubeflow namespace 裡有這個 Secret 再複製
  if kubectl -n "${KFP_NAMESPACE}" get secret mlpipeline-minio-artifact >/dev/null 2>&1; then
    kubectl get secret mlpipeline-minio-artifact -n "${KFP_NAMESPACE}" -o yaml \
      | sed "s/namespace: ${KFP_NAMESPACE}/namespace: kubeflow-user-example-com/" \
      | kubectl apply -f - \
      && echo "[INFO] 已將 mlpipeline-minio-artifact Secret 複製到 kubeflow-user-example-com" \
      || echo "[WARN] 複製 mlpipeline-minio-artifact Secret 失敗，請手動檢查"
  else
    echo "[WARN] 在 ${KFP_NAMESPACE} namespace 找不到 mlpipeline-minio-artifact Secret，略過複製動作"
  fi
else
  echo "[WARN] namespace kubeflow-user-example-com 遲遲沒有建立，略過 Secret 複製，請手動檢查"
fi
# ================== [8.1 修正版區塊結束] ================================================================

# ------------------------------------------------------------
# 9. Admission Webhook（Notebook 等資源需要）
# ------------------------------------------------------------
echo "============================================================"
echo "[9] Admission Webhook（Notebook 等資源需要）"
echo "============================================================"

kf_apply applications/admission-webhook/upstream/overlays/cert-manager

# ------------------------------------------------------------
# 10. Notebook / Volumes / PVC Viewer / Tensorboard
# ------------------------------------------------------------
echo "============================================================"
echo "[10] 安裝 Notebook / Volumes / PVC Viewer / Tensorboard (Web UI 相關)"
# ------------------------------------------------------------

# Notebook Controller
kf_apply applications/jupyter/notebook-controller/upstream/overlays/kubeflow

# Jupyter Web App
kf_apply applications/jupyter/jupyter-web-app/upstream/overlays/istio

# Volumes Web App
kf_apply applications/volumes-web-app/upstream/overlays/istio

# PVC Viewer Controller
kf_apply applications/pvcviewer-controller/upstream/base

# Tensorboard Controller
kf_apply applications/tensorboard/tensorboard-controller/upstream/overlays/kubeflow

# Tensorboards Web App
kf_apply applications/tensorboard/tensorboards-web-app/upstream/overlays/istio

echo "============================================================"
echo "[DONE] Kubeflow with Harbor Proxy (GHCR → ${HARBOR_PROXY_REGISTRY}) + MySQL 修復流程完成"
echo "============================================================"
