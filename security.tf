resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow workers Kubelets and pods to receive communication from the cluster control plane on the 443 port."
  protocol                 = "tcp"
  security_group_id        = "${module.eks.worker_security_group_id}"
  source_security_group_id = "${module.eks.cluster_security_group_id}"
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}