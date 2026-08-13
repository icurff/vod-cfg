# StreamForge — Development Environment (Maximum Cost Saving)
environment              = "dev"
kubernetes_version       = "1.34"
eks_system_instance_type = "t3.small"    # 2 vCPU 2GB RAM (Free Tier eligible)
eks_system_count         = 2
eks_spot_instance_types  = ["t3.small"]  # Free Tier eligible
eks_spot_max_count       = 1
s3_force_destroy         = true           # allow clean terraform destroy in dev
