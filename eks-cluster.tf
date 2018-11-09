module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "${var.cluster_name}"
  subnets      = ["${module.vpc.public_subnets}", "${module.vpc.private_subnets}"]
  tags         = "${map(var.cluster_name, var.environment)}"
  vpc_id       = "${module.vpc.vpc_id}"

  worker_groups = "${list(
                    map("asg_desired_capacity", var.asg_min_size,
                         "asg_max_size", var.asg_max_size,
                         "asg_min_size", var.asg_min_size,
                         "instance_type", var.instance_type,
                         "name", "workers",
                         "autoscaling_enabled", "true",
                         "protect_from_scale_in", "false",
                         "subnets", "${join(",", module.vpc.private_subnets)}",
                     )
  )}",

  worker_group_count = "1"
  map_users = "${var.map_users}"
}
