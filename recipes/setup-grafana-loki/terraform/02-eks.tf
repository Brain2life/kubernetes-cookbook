##############################################################################
# EKS Cluster with Managed Node Groups
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
##############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.35.0"

  cluster_name    = "eks-cluster"
  cluster_version = "1.32" # Kubernetes version

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
  }

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    workers = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 5
      desired_size = 4
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}