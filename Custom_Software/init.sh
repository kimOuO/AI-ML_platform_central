#!/bin/bash

cd Custom_Software
docker login 140.118.162.95 -u admin -p Harbor12345

# =====================================================
# 1 Build ai_ml_mt-model_dev
# =====================================================
bash 1_ai_ml_mt-model_dev.sh
sleep 5

# =====================================================
# 2 Build ai_ml_mt-model_dev-ml_img_mgt
# =====================================================
bash 2_ai_ml_mt-model_dev-ml_img_mgt.sh
sleep 5

# =====================================================
# 3 Build ai_ml_oom-metadata_mgt
# =====================================================
bash 3_ai_ml_oom-metadata_mgt.sh
sleep 5

# =====================================================
# 4 Build ai_ml_oom-file_mgt
# =====================================================
bash 4_ai_ml_oom-file_mgt.sh
sleep 5

# =====================================================
# 5 Build ai_ml_oom-ai_ml_mt_connector
# =====================================================
bash 5_ai_ml_oom-ai_ml_mt_connector.sh
sleep 5

# =====================================================
# 6 Build ai_ml_oom-bds_connector
# =====================================================
bash 6_ai_ml_oom-bds_connector.sh
sleep 5

# =====================================================
# 7 Build ai_ml_oom-agent_connector
# =====================================================
bash 7_ai_ml_oom-agent_connector.sh
sleep 5

# =====================================================
# 8 Build ai_ml_user_dashboard
# =====================================================
bash 8_ai_ml_user_dashboard.sh
sleep 5

# =====================================================
# 9 Build ai_ml_oom-authenticate_middleware
# =====================================================
bash 9_ai_ml_oom-authenticate_middleware.sh
sleep 5

# =====================================================
# 10 Build bds_mgt-topic_mgt
# =====================================================
bash 10_bds_mgt-topic_mgt.sh
sleep 5

# =====================================================
# 11 Init data 
# =====================================================
bash 11_init_data.sh
sleep 5

bash 8_ai_ml_user_dashboard.sh
