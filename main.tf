provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "blueharvest-terraform-state-storage-s3"
    region  = "eu-west-1"
    key     = "blueharvest/terraform/eks/test51"
  }
}

module "blueharvest-eks" {
  //source              = "s3::https://s3-eu-west-1.amazonaws.com/blueharvest-terraform-registry/terraform-aws-blueharvest-eks.zip"
  source              = "../terraform-aws-blueharvest-eks"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  eks_ami_id          = "ami-01e08d22b9439c15a" //amazon-eks-node-1.11-v20190109
  instance_type       = "t2.large"
  asg_min_size        = "5"
  asg_max_size        = "20"
  cluster_name        = "theharvest"
  cluster_zone        = "blueharvest.io"
  cluster_zone_id     = "Z31OVNF5EA1VAW"
  map_users           = []
  map_roles           = []
  map_users_count     = 0
  map_roles_count     = 0
}
