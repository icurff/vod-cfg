# StreamForge — Production Environment (Cost Optimized Budget Architecture)
environment              = "production"
eks_system_instance_type = "t3.medium"                                # 2 vCPU 4GB RAM (~$30/month)
eks_system_count         = 2                                          # 2 nodes for HA
eks_spot_instance_types  = ["t3.xlarge", "t3a.xlarge", "m5.xlarge"]  # diversity for spot availability
eks_spot_max_count       = 5
docdb_instance_class     = "db.r6g.large"   # Memory-optimized for production
docdb_cluster_size       = 2                # 1 primary + 1 replica
s3_force_destroy         = false
