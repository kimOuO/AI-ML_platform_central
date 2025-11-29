# AI-ML Platform Central
# AI-ML Platform Central Deployment Guide

本文件說明 AI-ML Platform Central 在 VM 與 Host 之間的必要 Port 映射、可修改項目，以及完整的部署流程。

---

## 🔌 Port Mapping（Host ↔ VM）

以下為所有系統需開放的對應 Port。  

**左欄為 VM Host 需開放的 Port，右欄 VM 需聆聽的 Port。**

| **HOST 端口（VM Host 要開這個，腳本也填這個）** | **VM 端口** | **服務名稱** |
| --- | --- | --- |
| 44901 | 44901 | authenticate_middleware |
| 44902 | 44902 | metadata_mgt (storage) |
| 44903 | 44903 | file_mgt (storage) |
| 44904 | 44904 | ai_ml_mt_connector (k8s) |
| 44905 | 44905 | bds_connector (topic_kafka) |
| 44906 | 44906 | agent_connector (agent) |
| 44907 | 44907 | topic_mgt (kafka) |
| 44908 | 44908 | kafdrop |
| 44909 | 44909 | kafka-1 |
| 44910 | 44910 | kafka-2 |
| 44911 | 44911 | kafka-3 |
| 44912 | 44912 | zookeeper_1 |
| 44913 | 44913 | zookeeper_2 |
| 44914 | 44914 | zookeeper_3 |
| 44915 | 44915 | ai_ml_user_dashboard (對外) |
| 44917 | 44917 | ai_ml_mt-model_dev |
| 44918 | 30002 | img_mgt |
| 44919 | 8080 | kubeflow |

---

## ⚠️ **請務必修改的內容**

### 1. **Port 設定須依照個人環境調整**
上述所有 Port 都需對應：
- 你的 VM Host Port（外部流量進入點）
- VM 內部對應 Port（腳本中填的值）

### 2. **IP 需改成你自己的 IP**
所有腳本中的：
- `CENTRAL_STORAGE_IP`
- `HARBOR_PROXY_REGISTRY`
- `HARBOR_CONTAINER_PORT`
- `NodePort` 服務 IP  
都需要修改成你的環境設定。

### 3. **Harbor Proxy Cache 已更新**
你需要：
- 查看 **完整部署腳本**（Out-of-the-box_Software 內）
- 找到 Harbor Proxy 設定 section
- 手動修改 Kubeflow / k8s 所需的 Harbor Proxy 參數

---

## 🚀 部署流程（依序執行）


```bash
  bash Environmental_Variables/environmental_variables.sh

  # =====================================================
  # Build Out-of-the-box Software
  # =====================================================
```bash
  bash Out-of-the-box_Software/init.sh

  # =====================================================
  # Build Out-of-the-box Software
  # =====================================================
```bash
  bash Custom_Software/init.sh

