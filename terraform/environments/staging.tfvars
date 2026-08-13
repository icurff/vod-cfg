# StreamForge — Staging Environment (Cost Optimized)
environment              = "staging"
eks_system_instance_type = "t3.medium"                      # 2 vCPU 4GB RAM
eks_system_count         = 1
eks_spot_instance_types  = ["t3.xlarge", "t3a.xlarge"]      # 4 vCPU 16GB Spot (~70% cheaper)
eks_spot_max_count       = 3
docdb_instance_class     = "db.t3.medium"
docdb_cluster_size       = 1
s3_force_destroy         = false
