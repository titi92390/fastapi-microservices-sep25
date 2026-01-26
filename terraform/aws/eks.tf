#################################
# EKS CLUSTER
#################################

resource "aws_eks_cluster" "this" {
  name     = "fastapi-microservices-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.34"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_eks_a.id,
      aws_subnet.private_eks_b.id
    ]

    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = {
    Name = "fastapi-microservices-eks"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

#################################
# EKS NODE GROUP
#################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_eks_a.id,
    aws_subnet.private_eks_b.id
  ]

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  tags = {
    Name = "fastapi-microservices-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}
